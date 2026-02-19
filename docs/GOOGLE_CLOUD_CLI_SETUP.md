# Google Cloud CLI (gcloud) setup

Steps to install and configure the Google Cloud CLI on your machine so you can deploy Cocoon (or other resources) to GCP.

---

## 1. Install gcloud

### Option A: Windows (direct installer — recommended)

If **winget** fails with "The specified path does not exist" for `GoogleCloudSDKInstaller.exe`, use the official installer instead:

1. **Download** the Windows installer:  
   https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe  
   (Or open https://cloud.google.com/sdk/docs/install#windows and click "Download the Google Cloud CLI installer".)
2. **Run** `GoogleCloudSDKInstaller.exe` (right‑click → Run as administrator if needed).
3. In the wizard: accept defaults, optionally "Run gcloud init", then finish.
4. **Restart** your terminal (or Cursor) so `gcloud` is on PATH.

### Option B: Windows (winget)

```powershell
winget install --id Google.CloudSDK --accept-package-agreements --accept-source-agreements
```

- If a **UAC prompt** appears, approve it. If you see "The specified path does not exist", use Option A (direct installer) instead.
- When finished, **close and reopen** your terminal so `gcloud` is on PATH.

### Option C: Linux / WSL

```bash
# Add repo and install (Debian/Ubuntu)
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
sudo apt-get update && sudo apt-get install -y google-cloud-cli
```

---

## 2. Add gcloud to PATH (if “command not found” in Bash)

If `gcloud` works in PowerShell or Command Prompt but **not** in Git Bash / WSL (`bash: gcloud: command not found`), add the SDK `bin` folder to your PATH.

**Typical install location (user install):**  
`C:\Users\<YourUser>\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin`

**Git Bash / MSYS2 Bash** — add to `~/.bashrc` (create the file if it doesn’t exist):

```bash
# Google Cloud SDK (adjust path if your install is elsewhere)
export PATH="$PATH:/c/Users/ASUS/AppData/Local/Google/Cloud SDK/google-cloud-sdk/bin"
```

Then run `source ~/.bashrc` or open a new terminal.

**Current session only (no file edit):**

```bash
export PATH="$PATH:/c/Users/ASUS/AppData/Local/Google/Cloud SDK/google-cloud-sdk/bin"
gcloud version
```

**Windows — permanent (system level so every new terminal sees it):**  

- **Option 1 (recommended):** Run the project script. From repo root (PowerShell):  
  `powershell -ExecutionPolicy Bypass -File shell/add-gcloud-path.ps1`  
  That adds gcloud to your **User** PATH. Close and reopen the terminal (and Cursor) so PATH is picked up.  

- **Option 2 (system-wide for all users):** Open PowerShell **as Administrator**, then run:  
  `powershell -ExecutionPolicy Bypass -File "C:\1\HyperlinksSpaceBot\shell\add-gcloud-path.ps1" -Machine`  
  (Use your actual repo path.) This adds gcloud to **Machine** PATH. Restart the terminal (and Cursor).  

- **Option 3 (GUI):** Start → “Environment variables” → “Edit the system environment variables” → “Environment Variables”. Under **User variables** (or **System variables** for all users) select “Path” → “Edit” → “New” → add `C:\Users\ASUS\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin` → OK. Restart the terminal and Cursor.

---

## 3. Log in and set project

Open a **new** terminal and run:

```bash
# Log in (opens browser)
gcloud auth login

# List projects and set default project
gcloud projects list
gcloud config set project YOUR_PROJECT_ID
```

Replace `YOUR_PROJECT_ID` with your Google Cloud project ID (e.g. `my-cocoon-project`). Create a project in the [Cloud Console](https://console.cloud.google.com/) if needed.

**Add an environment tag (if prompted):**  
If `gcloud config set project PROJECT_ID` warns that the project lacks an `environment` tag, add a Test environment with:

```bash
# 1) Get project number
PROJECT_NUM=$(gcloud projects describe hyperlinksspacebot --format="value(projectNumber)")

# 2) Create tag key "environment" (once per project)
gcloud resource-manager tags keys create environment \
  --parent=projects/hyperlinksspacebot \
  --description="Environment (Test, Development, Staging, Production)"

# 3) Create tag value "Test" (use the tag key name from step 2 output, e.g. tagKeys/281481095742953)
gcloud resource-manager tags values create Test \
  --parent=tagKeys/TAG_KEY_NUMERIC_ID \
  --description="Test environment"

# 4) Bind the tag to the project (use your project number and namespaced value: PROJECT_ID/environment/Test)
gcloud resource-manager tags bindings create \
  --parent=//cloudresourcemanager.googleapis.com/projects/$PROJECT_NUM \
  --tag-value=hyperlinksspacebot/environment/Test
```

Use `Production`, `Development`, or `Staging` instead of `Test` if needed.

---

## 4. Enable required APIs (for Cocoon / Compute)

When you’re ready to create VMs or use Cloud Run:

```bash
# Compute Engine (for VM-based Cocoon)
gcloud services enable compute.googleapis.com

# Cloud Run (for container-based Cocoon)
gcloud services enable run.googleapis.com

# Container Registry / Artifact Registry (for Docker images)
gcloud services enable artifactregistry.googleapis.com
```

---

## 5. Verify

```bash
gcloud version
gcloud config list
```

You should see your account and project. After this, you can follow [COCOON_GOOGLE_CLOUD.md](./COCOON_GOOGLE_CLOUD.md) to run Cocoon on GCP.
