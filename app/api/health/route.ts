import { NextResponse } from "next/server";

export function GET() {
  return NextResponse.json(
    { status: "ok", application: "pustaka-bersama", timestamp: new Date().toISOString() },
    { status: 200, headers: { "Cache-Control": "no-store" } },
  );
}
