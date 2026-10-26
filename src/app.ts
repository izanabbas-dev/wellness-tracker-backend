import express from "express";
import { healthRouter } from "./routes/health";
import { meRouter } from "./routes/me";
import { errorHandler, notFoundHandler } from "./shared/errors";

export const app = express();

app.use(express.json());
app.use(healthRouter);
app.use(meRouter);
app.use(notFoundHandler);
app.use(errorHandler);
