import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "YAAKOB | Be Free - Abundancia, Prosperidad y Libertad",
  description:
    "Descubre YAAKOB - Una experiencia inmersiva de abundancia, prosperidad, amor y libertad. Transforma tu vida con nuestras aplicaciones de bienestar y desarrollo personal.",
  keywords:
    "YAAKOB, abundancia, prosperidad, amor, libertad, bienestar, desarrollo personal, meditación, aplicaciones",
  authors: [{ name: "YAAKOB" }],
  robots: "index, follow",
  icons: {
    icon: "/logo.png",
    apple: "/logo.png",
  },
  openGraph: {
    type: "website",
    url: "https://yaakob.com/",
    title: "YAAKOB | Be Free - Abundancia, Prosperidad y Libertad",
    description:
      "Descubre YAAKOB - Una experiencia inmersiva de abundancia, prosperidad, amor y libertad.",
    images: "/logo.png",
    siteName: "YAAKOB",
    locale: "es_MX",
  },
  twitter: {
    card: "summary_large_image",
    title: "YAAKOB | Be Free - Abundancia, Prosperidad y Libertad",
    description:
      "Descubre YAAKOB - Una experiencia inmersiva de abundancia, prosperidad, amor y libertad.",
    images: "/logo.png",
  },
  other: {
    "theme-color": "#651200",
    "msapplication-TileColor": "#651200",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="es">
      <body>{children}</body>
    </html>
  );
}
