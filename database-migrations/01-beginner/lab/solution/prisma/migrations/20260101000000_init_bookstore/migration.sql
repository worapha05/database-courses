-- CreateTable
CREATE TABLE "authors" (
  "id" SERIAL NOT NULL,
  "name" TEXT NOT NULL,
  "country" TEXT,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "authors_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "books" (
  "id" SERIAL NOT NULL,
  "title" TEXT NOT NULL,
  "isbn" VARCHAR(13) NOT NULL,
  "price_cents" INTEGER NOT NULL,
  "author_id" INTEGER NOT NULL,
  "published_at" DATE,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "books_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "books_price_cents_check" CHECK ("price_cents" > 0)
);

-- CreateIndex
CREATE UNIQUE INDEX "books_isbn_key" ON "books" ("isbn");

-- AddForeignKey
ALTER TABLE "books" ADD CONSTRAINT "books_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "authors" ("id") ON DELETE RESTRICT ON UPDATE CASCADE;
