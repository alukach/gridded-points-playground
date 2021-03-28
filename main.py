from typing import Optional

from fastapi import FastAPI, Depends, Path, Response
from fastapi.responses import HTMLResponse
from fastapi.responses import FileResponse
from pydantic import BaseModel
import asyncpg


app = FastAPI()


async def get_db_conn():
    DB_NAME = "trace-demo"
    conn = await asyncpg.connect(f"postgresql://localhost/{DB_NAME}")
    yield conn
    await conn.close()


@app.get("/")
def viewer():
    return FileResponse("index.html")


class TileParams(BaseModel):
    z: int = Path(..., ge=0, le=30, description="Mercator tiles's zoom level"),
    x: int = Path(..., description="Mercator tiles's column"),
    y: int = Path(..., description="Mercator tiles's row"),
    
    def params(self):
        return self.dict(exclude_unset=True, by_alias=True)


@app.get(
    "/tiles/{z}/{x}/{y}.pbf",
    responses={200: {"content": {"application/x-protobuf": {}}}},
    response_class=Response,
)
async def tile(conn: asyncpg.Connection = Depends(get_db_conn), t: TileParams = Depends()):
    table = 'measurements'
    query = f"""
    WITH
        tile AS (
            SELECT ST_TileEnvelope($1,$2,$3) as tile
        ),
        t AS (
            SELECT
                COUNT(*) as count,
                ST_AsMVTGeom(geom, tile) as mvt
            FROM 
                {table}, tile
            WHERE
                geom && tile
            GROUP BY 
                geom, tile
        )
        SELECT
            (SELECT ST_AsMVT(t, 'default') FROM t);
    """
    row = await conn.fetchrow(query, t.z, t.x, t.y)
    return Response(
        content=row[0], status_code=200, media_type="application/x-protobuf"
    )
