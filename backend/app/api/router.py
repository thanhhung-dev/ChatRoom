from fastapi import APIRouter

from app.api.auth import router as auth_router
from app.api.feed import router as feed_router
from app.api.friends import router as friends_router
from app.api.messages import router as messages_router
from app.api.rooms import router as rooms_router
from app.api.users import router as users_router

api_router = APIRouter()
api_router.include_router(auth_router)
api_router.include_router(users_router)
api_router.include_router(rooms_router)
api_router.include_router(messages_router)
api_router.include_router(friends_router)
api_router.include_router(feed_router)
