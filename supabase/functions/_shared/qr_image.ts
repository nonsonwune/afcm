import { QRCode } from './deps.ts';

export async function generateQrPngBase64(text: string): Promise<string> {
  return await QRCode.toDataURL(text, {
    errorCorrectionLevel: 'M',
    type: 'image/png',
    margin: 1,
    width: 320,
    color: {
      dark: '#0B3D91',
      light: '#FFFFFF',
    },
  });
}

