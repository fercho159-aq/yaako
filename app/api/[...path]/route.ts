import { NextRequest, NextResponse } from "next/server";

const FIREBASE_API =
  process.env.FIREBASE_API ||
  "https://us-central1-airforce-echo.cloudfunctions.net";

async function proxyRequest(req: NextRequest) {
  const url = new URL(req.url);
  // Strip /api prefix to get the path to forward
  const path = url.pathname.replace(/^\/api/, "");
  const targetUrl = `${FIREBASE_API}${path}${url.search}`;

  const headers: HeadersInit = {
    "User-Agent":
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
    Accept: "application/json, */*",
    Origin: "https://airforceecho.com",
    Referer: "https://airforceecho.com/",
  };

  // Forward content-type for POST/PUT
  const contentType = req.headers.get("content-type");
  if (contentType) {
    headers["Content-Type"] = contentType;
  }

  const body =
    req.method !== "GET" && req.method !== "HEAD"
      ? await req.arrayBuffer()
      : undefined;

  try {
    const resp = await fetch(targetUrl, {
      method: req.method,
      headers,
      body,
    });

    const data = await resp.arrayBuffer();
    const responseHeaders = new Headers();
    responseHeaders.set(
      "Content-Type",
      resp.headers.get("Content-Type") || "application/json"
    );
    responseHeaders.set("Access-Control-Allow-Origin", "*");
    responseHeaders.set("Access-Control-Allow-Headers", "*");

    return new NextResponse(data, {
      status: resp.status,
      headers: responseHeaders,
    });
  } catch (e) {
    console.error(`[API PROXY ERROR] ${targetUrl}`, e);
    return NextResponse.json(
      { error: "Proxy error" },
      { status: 502 }
    );
  }
}

export async function GET(req: NextRequest) {
  return proxyRequest(req);
}

export async function POST(req: NextRequest) {
  return proxyRequest(req);
}

export async function OPTIONS() {
  return new NextResponse(null, {
    status: 200,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "*",
    },
  });
}
