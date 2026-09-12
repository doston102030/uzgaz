"use client";

import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { formatCurrencyShort } from "@/lib/format";

export function TopProductsChart({ data }: { data: { name: string; revenue: number }[] }) {
  return (
    <ResponsiveContainer width="100%" height={260}>
      <BarChart data={data} layout="vertical" margin={{ top: 4, right: 16, left: 0, bottom: 4 }}>
        <CartesianGrid horizontal={false} stroke="#e6eaf2" />
        <XAxis
          type="number"
          tickLine={false}
          axisLine={false}
          fontSize={11}
          tick={{ fill: "#94a3b8" }}
          tickFormatter={(v) => formatCurrencyShort(v).replace(" so'm", "")}
        />
        <YAxis
          type="category"
          dataKey="name"
          tickLine={false}
          axisLine={false}
          fontSize={12}
          width={140}
          tick={{ fill: "#334155" }}
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
        <Bar dataKey="revenue" fill="#2563eb" radius={[0, 6, 6, 0]} barSize={18} />
      </BarChart>
    </ResponsiveContainer>
  );
}
