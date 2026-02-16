// Vercel serverless function that securely proxies AI requests.
// Keeps upstream API key on the server side.
function maskSecret(value) {
  if (!value) return '(missing)';
  if (value.length <= 8) return '*'.repeat(value.length);
  return `${value.slice(0, 4)}...${value.slice(-4)}`;
}

function normalizeBackendUrl(value) {
  const raw = (value || '').trim();
  if (!raw) return '';
  if (/^https?:\/\//i.test(raw)) return raw;
  return `https://${raw}`;
}

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const apiKeyCandidates = [
    ['INNER_CALLS_KEY', process.env.INNER_CALLS_KEY || ''],
    ['BOT_API_KEY', process.env.BOT_API_KEY || ''],
    ['API_KEY', process.env.API_KEY || ''],
  ];
  const backendCandidates = [
    ['BOT_API_URL', process.env.BOT_API_URL || ''],
    ['AI_BACKEND_URL', process.env.AI_BACKEND_URL || ''],
  ];
  const selectedKey = apiKeyCandidates.find(([, v]) => v.trim()) || ['(none)', ''];
  const selectedBackend = backendCandidates.find(([, v]) => v.trim()) || ['(none)', ''];
  const apiKey = selectedKey[1];
  const backendUrl = normalizeBackendUrl(selectedBackend[1]);
  console.log(
    `[ENV][FRONT_API] key_source=${selectedKey[0]} key_preview=${maskSecret(apiKey)} backend_source=${selectedBackend[0]} backend_url=${backendUrl || '(missing)'}`
  );

  if (!apiKey || !backendUrl) {
    console.error(
      `[ENV][FRONT_API] missing config: key_present=${Boolean(apiKey)} backend_present=${Boolean(backendUrl)}`
    );
    return res.status(503).json({
      error: 'Server is not configured: INNER_CALLS_KEY/BOT_API_KEY/API_KEY or BOT_API_URL/AI_BACKEND_URL is missing',
    });
  }

  const body = req.body || {};
  const incomingMessages = Array.isArray(body.messages) ? body.messages : [];
  const filteredMessages = incomingMessages
    .map((m) => ({
      role: typeof m?.role === 'string' ? m.role : '',
      content: typeof m?.content === 'string' ? m.content : '',
    }))
    .filter(
      (m) =>
        ['system', 'user', 'assistant', 'tool'].includes(m.role) &&
        m.content.trim().length > 0
    );

  if (filteredMessages.length === 0) {
    return res.status(400).json({ error: 'messages array cannot be empty' });
  }

  try {
    const upstream = await fetch(`${backendUrl.replace(/\/$/, '')}/api/chat`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': apiKey,
      },
      body: JSON.stringify({
        messages: filteredMessages,
        stream: false,
      }),
    });

    const raw = await upstream.text();
    if (!upstream.ok) {
      console.error(
        `[FRONT_API] upstream failed status=${upstream.status} backend_url=${backendUrl.replace(/\/$/, '')}/api/chat`
      );
      return res.status(upstream.status).json({
        error: 'AI upstream request failed',
        detail: raw.slice(0, 500),
      });
    }

    // AI backend returns NDJSON. Extract final response.
    let finalResponse = '';
    const lines = raw
      .split('\n')
      .map((line) => line.trim())
      .filter(Boolean);

    for (const line of lines) {
      try {
        const parsed = JSON.parse(line);
        if (typeof parsed.response === 'string' && parsed.response.trim()) {
          finalResponse = parsed.response;
        } else if (
          typeof parsed.token === 'string' &&
          !finalResponse
        ) {
          finalResponse += parsed.token;
        }
      } catch (_) {
        // Skip malformed chunks
      }
    }

    if (!finalResponse.trim()) {
      return res.status(502).json({ error: 'AI response was empty' });
    }

    return res.status(200).json({ response: finalResponse });
  } catch (error) {
    console.error(`[FRONT_API] fetch error backend_url=${backendUrl}: ${String(error)}`);
    return res.status(502).json({
      error: 'Failed to reach AI backend',
      detail: String(error),
    });
  }
};
