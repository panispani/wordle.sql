FROM postgres:14

# Create working dir and copy SQL + play script
USER postgres
WORKDIR /home/postgres
COPY --chown=postgres:postgres wordle.sql play.sh words.txt .

# Init database cluster at build time
ENV PGDATA=/home/postgres/db
RUN initdb -D $PGDATA > /dev/null

# Start postgres server, run game, stop postgres server
CMD bash -c "\
    pg_ctl -D \$PGDATA -o '-c listen_addresses=localhost' -w start >/dev/null && \
    ./play.sh && \
    pg_ctl -D \$PGDATA stop -m fast >/dev/null"