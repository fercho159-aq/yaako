import { NextRequest, NextResponse } from "next/server";

const GCS_BASE =
  process.env.GCS_BASE || "https://storage.googleapis.com";

async function proxyRequest(req: NextRequest) {
  const url = new URL(req.url);
  // Strip /api/gcs prefix to get the GCS path
  const path = url.pathname.replace(/^\/api\/gcs/, "");
  const targetUrl = `${GCS_BASE}${path}${url.search}`;

  try {
    const resp = await fetch(targetUrl, {
      method: req.method,
      headers: {
        "User-Agent":
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
        Accept: "*/*",
        Origin: "https://airforceecho.com",
        Referer: "https://airforceecho.com/",
      },
    });

    const data = await resp.arrayBuffer();
    const responseHeaders = new Headers();
    responseHeaders.set(
      "Content-Type",
      resp.headers.get("Content-Type") || "application/octet-stream"
    );
    responseHeaders.set("Access-Control-Allow-Origin", "*");
    responseHeaders.set("Access-Control-Allow-Headers", "*");
    // Cache GCS responses for 1 hour
    responseHeaders.set("Cache-Control", "public, max-age=3600");

    return new NextResponse(data, {
      status: resp.status,
      headers: responseHeaders,
    });
  } catch (e) {
    console.error(`[GCS PROXY ERROR] ${targetUrl}`, e);
    return NextResponse.json(
      { error: "Proxy error" },
      { status: 502 }
    );
  }
}

export async function GET(req: NextRequest) {
  return proxyRequest(req);
}

export async function OPTIONS() {
  return new NextResponse(null, {
    status: 200,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, OPTIONS",
      "Access-Control-Allow-Headers": "*",
    },
  });
}
