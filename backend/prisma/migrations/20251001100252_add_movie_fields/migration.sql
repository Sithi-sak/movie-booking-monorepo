-- CreateTable
CREATE TABLE "public"."users" (
    "id" SERIAL NOT NULL,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "phone" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."movies" (
    "id" SERIAL NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "genre" TEXT,
    "duration" INTEGER,
    "rating" TEXT,
    "score" DOUBLE PRECISION,
    "poster_url" TEXT,
    "backdrop_url" TEXT,
    "trailer_url" TEXT,
    "language" TEXT,
    "director" TEXT,
    "cast" JSONB,
    "release_date" TIMESTAMP(3),
    "status" TEXT NOT NULL DEFAULT 'coming_soon',
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "movies_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."theaters" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "address" TEXT NOT NULL,
    "city" TEXT NOT NULL,
    "state" TEXT,
    "zip_code" TEXT,
    "phone" TEXT,
    "screens" INTEGER NOT NULL DEFAULT 1,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "theaters_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."showtimes" (
    "id" SERIAL NOT NULL,
    "movie_id" INTEGER NOT NULL,
    "theater_id" INTEGER NOT NULL,
    "screen_number" INTEGER NOT NULL,
    "show_time" TIMESTAMP(3) NOT NULL,
    "available_seats" INTEGER NOT NULL,
    "total_seats" INTEGER NOT NULL,
    "price" DOUBLE PRECISION NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "showtimes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."bookings" (
    "id" SERIAL NOT NULL,
    "user_id" INTEGER NOT NULL,
    "showtime_id" INTEGER NOT NULL,
    "booking_reference" TEXT NOT NULL,
    "seats" TEXT NOT NULL,
    "total_amount" DOUBLE PRECISION NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'confirmed',
    "booking_date" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "payment_status" TEXT NOT NULL DEFAULT 'pending',
    "payment_reference" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "bookings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."seats" (
    "id" SERIAL NOT NULL,
    "theater_id" INTEGER NOT NULL,
    "screen_number" INTEGER NOT NULL,
    "seat_number" TEXT NOT NULL,
    "row_name" TEXT NOT NULL,
    "seat_column" INTEGER NOT NULL,
    "seat_type" TEXT NOT NULL DEFAULT 'regular',
    "price" DOUBLE PRECISION,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "is_aisle" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "seats_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."booking_seats" (
    "id" SERIAL NOT NULL,
    "booking_id" INTEGER NOT NULL,
    "seat_id" INTEGER NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'confirmed',
    "held_until" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "booking_seats_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "public"."users"("email");

-- CreateIndex
CREATE INDEX "users_email_idx" ON "public"."users"("email");

-- CreateIndex
CREATE INDEX "movies_genre_idx" ON "public"."movies"("genre");

-- CreateIndex
CREATE INDEX "movies_release_date_idx" ON "public"."movies"("release_date");

-- CreateIndex
CREATE INDEX "movies_is_active_idx" ON "public"."movies"("is_active");

-- CreateIndex
CREATE INDEX "movies_title_idx" ON "public"."movies"("title");

-- CreateIndex
CREATE INDEX "movies_status_idx" ON "public"."movies"("status");

-- CreateIndex
CREATE INDEX "theaters_city_idx" ON "public"."theaters"("city");

-- CreateIndex
CREATE INDEX "theaters_is_active_idx" ON "public"."theaters"("is_active");

-- CreateIndex
CREATE INDEX "showtimes_movie_id_idx" ON "public"."showtimes"("movie_id");

-- CreateIndex
CREATE INDEX "showtimes_theater_id_idx" ON "public"."showtimes"("theater_id");

-- CreateIndex
CREATE INDEX "showtimes_show_time_idx" ON "public"."showtimes"("show_time");

-- CreateIndex
CREATE INDEX "showtimes_movie_id_theater_id_idx" ON "public"."showtimes"("movie_id", "theater_id");

-- CreateIndex
CREATE INDEX "showtimes_show_time_is_active_idx" ON "public"."showtimes"("show_time", "is_active");

-- CreateIndex
CREATE UNIQUE INDEX "bookings_booking_reference_key" ON "public"."bookings"("booking_reference");

-- CreateIndex
CREATE INDEX "bookings_user_id_idx" ON "public"."bookings"("user_id");

-- CreateIndex
CREATE INDEX "bookings_showtime_id_idx" ON "public"."bookings"("showtime_id");

-- CreateIndex
CREATE INDEX "bookings_booking_reference_idx" ON "public"."bookings"("booking_reference");

-- CreateIndex
CREATE INDEX "bookings_status_idx" ON "public"."bookings"("status");

-- CreateIndex
CREATE INDEX "bookings_payment_status_idx" ON "public"."bookings"("payment_status");

-- CreateIndex
CREATE INDEX "seats_theater_id_idx" ON "public"."seats"("theater_id");

-- CreateIndex
CREATE INDEX "seats_theater_id_screen_number_idx" ON "public"."seats"("theater_id", "screen_number");

-- CreateIndex
CREATE INDEX "seats_seat_type_idx" ON "public"."seats"("seat_type");

-- AddForeignKey
ALTER TABLE "public"."showtimes" ADD CONSTRAINT "showtimes_movie_id_fkey" FOREIGN KEY ("movie_id") REFERENCES "public"."movies"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."showtimes" ADD CONSTRAINT "showtimes_theater_id_fkey" FOREIGN KEY ("theater_id") REFERENCES "public"."theaters"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."bookings" ADD CONSTRAINT "bookings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."bookings" ADD CONSTRAINT "bookings_showtime_id_fkey" FOREIGN KEY ("showtime_id") REFERENCES "public"."showtimes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."seats" ADD CONSTRAINT "seats_theater_id_fkey" FOREIGN KEY ("theater_id") REFERENCES "public"."theaters"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."booking_seats" ADD CONSTRAINT "booking_seats_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."booking_seats" ADD CONSTRAINT "booking_seats_seat_id_fkey" FOREIGN KEY ("seat_id") REFERENCES "public"."seats"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
