/**
 * Run AFTER Prisma migration that adds nullable display_name.
 *
 * npx ts-node prisma_backfill_display_name.ts
 *
 * Idempotent: only fills NULL display_name.
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const BATCH = 500;

async function main() {
  for (;;) {
    const batch = await prisma.user.findMany({
      where: { displayName: null },
      select: { id: true, name: true, email: true },
      take: BATCH,
      orderBy: { id: 'asc' },
    });

    if (batch.length === 0) break;

    await prisma.$transaction(
      batch.map((u) =>
        prisma.user.update({
          where: { id: u.id },
          data: {
            displayName: (u.name && u.name.trim()) || u.email,
          },
        }),
      ),
    );

    console.log(`Backfilled ${batch.length} users (last id=${batch.at(-1)?.id})`);
  }
}

main()
  .catch((err) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
