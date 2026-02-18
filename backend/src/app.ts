import express from "express";
import path from "path";
import { fileURLToPath } from "url";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import dotenv from "dotenv";
import productRoutes from "./routes/product.routes.js";
import orderRoutes from "./routes/order.routes.js";
import userRoutes from "./routes/user.routes.js";

dotenv.config();

const app = express();

app.use((helmet as any)());
app.use(cors());
app.use(morgan("dev"));
app.use(express.json());

app.get("/health", (_req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

app.use("/api/products", productRoutes);
app.use("/api/orders", orderRoutes);
app.use("/api/users", userRoutes);

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Serve static files from the frontend/dist directory
app.use(express.static(path.join(__dirname, "../../frontend/dist")));

// Handle client-side routing by serving index.html for all other routes
app.get("*", (_req, res) => {
  res.sendFile(path.join(__dirname, "../../frontend/dist/index.html"));
});

app.use(
  (
    err: Error,
    _req: express.Request,
    res: express.Response,
    _next: express.NextFunction,
  ) => {
    console.error(err.stack);
    res.status(500).json({ error: "Internal server error" });
  },
);

export default app;
