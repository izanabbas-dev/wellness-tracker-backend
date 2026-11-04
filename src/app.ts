import cors from "cors";
import express from "express";
import helmet from "helmet";
import { healthRouter } from "./routes/health";
import { errorHandler, notFoundHandler } from "./shared/errors";

export const app = express();

app.disable("x-powered-by");
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: "100kb" }));
app.use(healthRouter);
app.use(notFoundHandler);
app.use(errorHandler);
