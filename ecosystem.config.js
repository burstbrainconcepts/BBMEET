module.exports = {
    apps: [
        {
            name: 'bb.meet.server.api',
            script: 'dist/main.js',
            instances: 1,
            exec_mode: 'fork',
            autorestart: true,
            watch: false,
            max_memory_restart: '3G',
            env: {
                NODE_ENV: 'production',
                NODE_TLS_REJECT_UNAUTHORIZED: '0',
            },
            error_file: '/home/ec2-user/bb-sdk-api/logs/error.log', // Combined error log
            out_file: '/home/ec2-user/bb-sdk-api/logs/out.log',     // Combined out log
        },
    ],
};
