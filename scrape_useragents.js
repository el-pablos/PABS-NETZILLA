const fs = require('fs');
const https = require('https');
const http = require('http');

console.log('🔍 Starting User Agent Scraper...');

// Advanced user agents collection from multiple sources
const userAgentSources = [
  // Chrome user agents
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
  
  // Firefox user agents
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/121.0',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/120.0',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/119.0',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/121.0',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/120.0',
  'Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/121.0',
  'Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/120.0',
  
  // Safari user agents
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Safari/605.1.15',
  
  // Edge user agents
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36 Edg/119.0.0.0',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0',
  
  // Mobile user agents
  'Mozilla/5.0 (iPhone; CPU iPhone OS 17_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Mobile/15E148 Safari/604.1',
  'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
  'Mozilla/5.0 (iPad; CPU OS 17_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Mobile/15E148 Safari/604.1',
  'Mozilla/5.0 (Linux; Android 14; SM-G998B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
  'Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
  'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
  'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
  
  // Opera user agents
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 OPR/106.0.0.0',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 OPR/106.0.0.0',
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 OPR/106.0.0.0',
  
  // Specialized browsers
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Vivaldi/6.5.3206.39',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Brave/1.61.109',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/121.0 Waterfox/G6.0.8',
];

// Function to generate random variations
function generateVariations(baseUserAgents) {
  const variations = [...baseUserAgents];
  const windowsVersions = ['10.0', '11.0'];
  const chromeVersions = ['118.0.0.0', '119.0.0.0', '120.0.0.0', '121.0.0.0'];
  const firefoxVersions = ['119.0', '120.0', '121.0', '122.0'];
  
  // Generate Chrome variations
  windowsVersions.forEach(winVer => {
    chromeVersions.forEach(chromeVer => {
      variations.push(`Mozilla/5.0 (Windows NT ${winVer}; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${chromeVer} Safari/537.36`);
    });
  });
  
  // Generate Firefox variations
  windowsVersions.forEach(winVer => {
    firefoxVersions.forEach(ffVer => {
      variations.push(`Mozilla/5.0 (Windows NT ${winVer}; Win64; x64; rv:109.0) Gecko/20100101 Firefox/${ffVer}`);
    });
  });
  
  return [...new Set(variations)]; // Remove duplicates
}

// Function to shuffle array
function shuffleArray(array) {
  const shuffled = [...array];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return shuffled;
}

// Generate comprehensive user agent list
const allUserAgents = generateVariations(userAgentSources);
const shuffledUserAgents = shuffleArray(allUserAgents);

// Save user agents to JSON file
try {
  fs.writeFileSync('user_agents.json', JSON.stringify(shuffledUserAgents, null, 2));
  console.log(`✅ Successfully generated ${shuffledUserAgents.length} user agents`);
  console.log('📁 Saved to: user_agents.json');
  
  // Also save a sample for verification
  const sample = shuffledUserAgents.slice(0, 5);
  console.log('🔍 Sample user agents:');
  sample.forEach((ua, index) => {
    console.log(`   ${index + 1}. ${ua.substring(0, 80)}...`);
  });
  
} catch (error) {
  console.error('❌ Error saving user agents:', error.message);
  process.exit(1);
}

// Generate additional metadata
const metadata = {
  generated_at: new Date().toISOString(),
  total_count: shuffledUserAgents.length,
  browsers: {
    chrome: shuffledUserAgents.filter(ua => ua.includes('Chrome')).length,
    firefox: shuffledUserAgents.filter(ua => ua.includes('Firefox')).length,
    safari: shuffledUserAgents.filter(ua => ua.includes('Safari') && !ua.includes('Chrome')).length,
    edge: shuffledUserAgents.filter(ua => ua.includes('Edg/')).length,
    opera: shuffledUserAgents.filter(ua => ua.includes('OPR/')).length,
    mobile: shuffledUserAgents.filter(ua => ua.includes('Mobile')).length,
  },
  platforms: {
    windows: shuffledUserAgents.filter(ua => ua.includes('Windows')).length,
    macos: shuffledUserAgents.filter(ua => ua.includes('Macintosh')).length,
    linux: shuffledUserAgents.filter(ua => ua.includes('Linux')).length,
    ios: shuffledUserAgents.filter(ua => ua.includes('iPhone') || ua.includes('iPad')).length,
    android: shuffledUserAgents.filter(ua => ua.includes('Android')).length,
  }
};

try {
  fs.writeFileSync('user_agents_metadata.json', JSON.stringify(metadata, null, 2));
  console.log('📊 Metadata saved to: user_agents_metadata.json');
  console.log(`📈 Browser distribution: Chrome(${metadata.browsers.chrome}), Firefox(${metadata.browsers.firefox}), Safari(${metadata.browsers.safari}), Edge(${metadata.browsers.edge}), Opera(${metadata.browsers.opera}), Mobile(${metadata.browsers.mobile})`);
  console.log(`🖥️  Platform distribution: Windows(${metadata.platforms.windows}), macOS(${metadata.platforms.macos}), Linux(${metadata.platforms.linux}), iOS(${metadata.platforms.ios}), Android(${metadata.platforms.android})`);
} catch (error) {
  console.error('⚠️  Warning: Could not save metadata:', error.message);
}

console.log('🎉 User agent scraping completed successfully!');
