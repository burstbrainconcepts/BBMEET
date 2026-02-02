import {
  ClassSerializerInterceptor,
  ValidationPipe,
  VersioningType,
} from '@nestjs/common';
import { Logger as NestLogger } from '@nestjs/common';
import { NestFactory, Reflector } from '@nestjs/core';
import { AppModule } from './app.module';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { useContainer } from 'class-validator';
import validationOptions from './utils/validation-options';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import {
  NestFastifyApplication,
  FastifyAdapter,
} from '@nestjs/platform-fastify';
import { EPackage, getProtoPath, getIncludeDirs } from 'waterbus-proto';
import { EnvironmentConfigService } from './core/config/environment/environments';
import { IoAdapter } from '@nestjs/platform-socket.io';
import fastifyCors from '@fastify/cors';

async function bootstrap() {
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter({
      pluginTimeout: 60000,  // Increase timeout to 60s for async service initialization
      constraints: {
        // Disable automatic CORS plugin to prevent duplicate registration
      }
    }),
  );

  useContainer(app.select(AppModule), { fallbackOnErrors: true });
  const configService = app.get(EnvironmentConfigService);

  // Enable CORS using Fastify's instance directly for proper preflight handling
  // CORS origins can be configured via CORS_ORIGINS env var (comma-separated)
  // If not set, allows all origins (for maximum compatibility)
  const fastifyInstance = app.getHttpAdapter().getInstance();
  const corsOriginsEnv = process.env.CORS_ORIGINS || '';
  const corsOrigins = corsOriginsEnv
    ? corsOriginsEnv.split(',').map((o) => o.trim()).filter(Boolean)
    : null; // null = allow all origins

  await fastifyInstance.register(fastifyCors, {
    origin: corsOrigins
      ? (origin, callback) => {
          // Allow requests with no origin (like mobile apps or Postman)
          if (!origin) {
            return callback(null, true);
          }
          // Check if origin is in allowed list
          if (corsOrigins.includes(origin)) {
            return callback(null, true);
          }
          // For development, always allow localhost
          if (origin.startsWith('http://localhost:') || origin.startsWith('https://localhost:')) {
            return callback(null, true);
          }
          // Reject other origins
          return callback(new Error('Not allowed by CORS'), false);
        }
      : true, // Allow all origins if CORS_ORIGINS not set
    methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE', 'OPTIONS'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'api-key',
      'X-Requested-With',
      'Accept',
      'Origin',
      'Access-Control-Request-Method',
      'Access-Control-Request-Headers',
    ],
    credentials: true,
    preflight: true,
    preflightContinue: false,
  });

  app.enableShutdownHooks();
  app.setGlobalPrefix(configService.getApiPrefix(), {
    exclude: ['/', '/socket.io'],
  });
  app.enableVersioning({
    type: VersioningType.URI,
  });
  app.useGlobalPipes(new ValidationPipe(validationOptions));
  app.useGlobalInterceptors(new ClassSerializerInterceptor(app.get(Reflector)));
  app.useWebSocketAdapter(new IoAdapter(app));

  const options = new DocumentBuilder()
    .setTitle('BB Meet Server API')
    .setDescription(
      'Open source video conferencing app built on latest WebRTC SDK. Android/iOS/MacOS/Web',
    )
    .setVersion('2.0')
    .addApiKey(
      {
        type: 'apiKey',
        in: 'header',
        name: 'api-key',
      },
      'api-key',
    )
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, options);

  SwaggerModule.setup('docs', app, document);

  const authGrpcUrl = configService.getAuthGrpcUrl();
  const whiteBoardGrpcUrl = configService.getWhiteBoardGrpcUrl();
  const meetingGrpcUrl = configService.getMeetingGrpcUrl();

  const authMicroserviceOptions: MicroserviceOptions = {
    transport: Transport.GRPC,
    options: {
      package: EPackage.AUTH,
      protoPath: getProtoPath(EPackage.AUTH),
      url: authGrpcUrl,
      loader: {
        includeDirs: [getIncludeDirs()],
      },
    },
  };
  const whiteBoardMicroserviceOptions: MicroserviceOptions = {
    transport: Transport.GRPC,
    options: {
      package: EPackage.WHITEBOARD,
      protoPath: getProtoPath(EPackage.WHITEBOARD),
      url: whiteBoardGrpcUrl,
      loader: {
        includeDirs: [getIncludeDirs()],
      },
    },
  };

  const meetingMicroserviceOptions: MicroserviceOptions = {
    transport: Transport.GRPC,
    options: {
      package: EPackage.MEETING,
      protoPath: getProtoPath(EPackage.MEETING),
      url: meetingGrpcUrl,
      loader: {
        includeDirs: [getIncludeDirs()],
      },
    },
  };

  app.connectMicroservice(authMicroserviceOptions);
  app.connectMicroservice(whiteBoardMicroserviceOptions);
  app.connectMicroservice(meetingMicroserviceOptions);
  await app.startAllMicroservices();
  await app.listen(configService.getPort(), '0.0.0.0');
  return app.getUrl();
}

(async (): Promise<void> => {
  try {
    const url = await bootstrap();
    NestLogger.log(url, 'Bootstrap');
  } catch (error) {
    NestLogger.error(error, 'Bootstrap');
  }
})();
