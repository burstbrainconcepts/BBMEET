
// Force SSL settings patch
import { registerAs } from '@nestjs/config';

export default registerAs('database', () => {
    return {
        url: process.env.DATABASE_URL,
        type: 'postgres',
        host: process.env.DATABASE_HOST,
        port: 5432,
        password: process.env.DATABASE_PASSWORD,
        name: process.env.DATABASE_NAME,
        username: process.env.DATABASE_USERNAME,
        synchronize: false,
        maxConnections: 100,
        sslEnabled: true,
        rejectUnauthorized: false,
        // Explicitly set SSL option object for TypeORM/pg
        ssl: {
            rejectUnauthorized: false,
        }
    };
});
