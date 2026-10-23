import express from "express";
import { healthRouter } from "./routes/health";
import { errorHandler, notFoundHandler } from "./shared/errors";

export const app = express();

app.use(express.json());
app.use(healthRouter);
app.use(notFoundHandler);
app.use(errorHandler);
