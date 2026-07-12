const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('Building Tailwind CSS...');
try {
    execSync('npx tailwindcss -i ./css/input.css -o ./css/output.css --minify', { stdio: 'inherit' });
} catch (error) {
    console.error('Tailwind CSS build failed:', error.message);
    process.exit(1);
}

console.log('Creating dist/ directory...');
if (fs.existsSync('dist')) {
    fs.rmSync('dist', { recursive: true, force: true });
}
fs.mkdirSync('dist');

// Files and directories to copy to output
const targets = [
    'index.html',
    'index-new.html',
    'css',
    'js',
    'pages',
    'assets'
];

targets.forEach(target => {
    if (fs.existsSync(target)) {
        console.log(`Copying ${target} to dist/${target}...`);
        try {
            fs.cpSync(target, path.join('dist', target), { recursive: true });
        } catch (err) {
            console.error(`Failed to copy ${target}:`, err.message);
        }
    } else {
        console.log(`Warning: Target ${target} does not exist, skipping.`);
    }
});

console.log('Build completed successfully!');
