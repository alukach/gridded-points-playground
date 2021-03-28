# TRACE Demo App

## Setup 

### Database

```sh
make create_db && make
```

### API

```sh
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Running

```sh
uvicorn main:app --reload
```

Navigate to http://localhost:8000

## Interesting Reading

* http://www.danbaston.com/posts/2016/12/17/generating-test-data-in-postgis.html