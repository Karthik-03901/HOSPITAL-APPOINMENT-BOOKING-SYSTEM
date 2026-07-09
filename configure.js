const fs = require('fs');
const path = require('path');

const envPath = path.join(__dirname, '.env');
if (!fs.existsSync(envPath)) {
    console.error('.env file not found!');
    process.exit(1);
}

const envContent = fs.readFileSync(envPath, 'utf8');
const env = {};
envContent.split(/\r?\n/).forEach(line => {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) return;
    const parts = trimmed.split('=');
    if (parts.length >= 2) {
        const key = parts[0].trim();
        let val = parts.slice(1).join('=').trim();
        if (val.startsWith('"') && val.endsWith('"')) val = val.slice(1, -1);
        if (val.startsWith("'") && val.endsWith("'")) val = val.slice(1, -1);
        env[key] = val;
    }
});

const clientPath = path.join(__dirname, 'js', 'supabaseClient.js');
if (!fs.existsSync(clientPath)) {
    console.error('js/supabaseClient.js not found!');
    process.exit(1);
}

let clientContent = fs.readFileSync(clientPath, 'utf8');

// Replace URL and ANON KEY
const urlRegex = /const SUPABASE_URL = ".*";/;
const keyRegex = /const SUPABASE_ANON_KEY = ".*";/;

if (env.SUPABASE_URL) {
    clientContent = clientContent.replace(urlRegex, `const SUPABASE_URL = "${env.SUPABASE_URL}";`);
}
if (env.SUPABASE_ANON_KEY) {
    clientContent = clientContent.replace(keyRegex, `const SUPABASE_ANON_KEY = "${env.SUPABASE_ANON_KEY}";`);
}

fs.writeFileSync(clientPath, clientContent, 'utf8');
console.log('Successfully injected environment keys into js/supabaseClient.js!');
