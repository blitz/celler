# Migration from Attic

This guide explains how to migrate from Attic to Celler.

> [!CAUTION]
> So far the database layouts are compatible, but the migration process is not regularly tested. Use at your own risk and please backup your database before proceeding.

## General Notes

### Don't Use Attic CLI with a Celler Server

Attic CLI is not compatible with a Celler server. Use the Celler CLI instead.

## Configuration Changes

### Database URLs

Because of updated dependencies, Celler is stricter about the format of database URLs. See these [example URLs](https://docs.rs/sqlx/0.9.0/sqlx/postgres/struct.PgConnectOptions.html#example-urls) if you encounter problems.

Specifically, the `database.url` setting may need to be updated because the default username is no longer the username of the user account but "anonymous". To specify a username, use the `user` query parameter:

```nix
database.url = "postgresql:///cellerd?user=cellerd";
```
