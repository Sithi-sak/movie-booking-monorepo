```
npm install @prisma/client dotenv
```

```
npm install prisma --save-dev
npm install jsonwebtoken bcryptjs joi
```


movie-booking-backend/
├── prisma/
│   └── schema.prisma          # Database models
├── src/
│   ├── middlewares/
│   │   └── auth.js            # JWT authentication middleware
│   ├── routes/
│   │   ├── auth.js            # Login/Register
│   │   ├── movies.js          # Movie listings
│   │   ├── bookings.js        # Seat selection & booking
│   │   └── tickets.js         # View tickets
│   ├── controllers/           # Business logic
│   └── utils/                 # JWT helpers, etc.
├── app.js
└── package.json


