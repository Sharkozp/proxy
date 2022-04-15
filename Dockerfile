FROM balenalib/raspberrypi4-64-python:3.10

RUN apk update && apk add --update git gcc libc-dev libffi-dev
WORKDIR mhddos_proxy
COPY ./requirements.txt .
RUN pip3 install --target=/mhddos_proxy/dependencies -r requirements.txt
COPY . .

FROM balenalib/raspberrypi4-64-golang:1.16 as bomber
ENV REPO="github.com/codesenberg/bombardier"
ENV REPO_EDIT="github.com/PXEiYyMH8F/bombardier@78-add-proxy-support"
WORKDIR /app
RUN go mod init bombardier_tmp
RUN go mod edit -replace ${REPO}=${REPO_EDIT}
RUN go get ${REPO}
RUN CGO_ENABLED=0 go install -v -ldflags '-extldflags "-static"' ${REPO}

FROM balenalib/raspberrypi4-64-python:3.10
WORKDIR mhddos_proxy
COPY --from=builder	/mhddos_proxy .
COPY --from=bomber /go/bin/bombardier /root/go/bin/bombardier
ENV PYTHONPATH="${PYTHONPATH}:/mhddos_proxy/dependencies" PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1

ENTRYPOINT ["python3", "./runner.py -t 2400 --itarmy --debug"]
