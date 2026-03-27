const { getDefaultConfig } = require('expo/metro-config');
const exclusionList = require('metro-config/src/defaults/exclusionList');

const config = getDefaultConfig(__dirname);

// Exclude all files/folders under release (Windows and POSIX)
config.resolver.blockList = exclusionList([
  /release[\\\/].*/,
]);

module.exports = config;
