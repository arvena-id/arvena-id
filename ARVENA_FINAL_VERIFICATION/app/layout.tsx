import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata={title:"ARVENA",description:"Service Business Operating System"};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="id"><body>{children}</body></html>}
