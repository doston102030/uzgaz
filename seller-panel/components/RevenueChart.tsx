"use client";

import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import { formatCurrencyShort } from "@/lib/format";

export function RevenueChart({ data }: { data: { date: string; revenue: number }[] }) {
  return (
    <ResponsiveContainer width="100%" height={260}>
      <AreaChart data={data} margin={{ top: 10, right: 12, left: 0, bottom: 0 }}>
        <defs>
          <linearGradient id="revenueFill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#2563eb" stopOpacity={0.28} />
            <stop offset="100%" stopColor="#2563eb" stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid vertical={false} stroke="#e6eaf2" />
        <XAxis
          dataKey="date"
          tickLine={false}
          axisLine={false}
          fontSize={11}
          tick={{ fill: "#94a3b8" }}
          minTickGap={24}
        />
        <YAxis
          tickLine={false}
          axisLine={false}
          fontSize={11}
          tick={{ fill: "#94a3b8" }}
          tickFormatter={(v) => formatCurrencyShort(v).replace(" so'm", "")}
          width={54}
        />
        <Tooltip
          formatter={(value) => [formatCurrencyShort(Number(value) || 0), "Tushum"]}
          contentStyle={{
            borderRadius: 12,
            border: "1px solid #e6eaf2",
            fontSize: 12,
            boxShadow: "0 8px 24px rgba(11,21,38,0.08)",
          }}
        />
        <Area
          type="monotone"
          dataKey="revenue"
          stroke="#2563eb"
          strokeWidth={2.5}
          fill="url(#revenueFill)"
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}
