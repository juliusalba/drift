import { NextResponse } from 'next/server';
import { getRunIndex } from '@/lib/data';

export async function GET() {
  const index = await getRunIndex();
  return NextResponse.json(index);
}
