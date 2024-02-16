This container does the job of receiving an e-mail for a specified domain
and spawning an instance of another container to do "something" with the
e-mail.  That's it.  All very simple and straightforward.  You would
think...

# ARM64 Support

This is a fork of the official Discourse mail-receiver, built for arm64.  It is somewhat experimental, and if you encounter problems, please do not pester the Discourse core team.
Report issues at https://github.com/mpalmer/discourse-mail-receiver instead.

To use this `arm64` build, follow the [official instructions](https://meta.discourse.org/t/configure-direct-delivery-incoming-email-for-self-hosted-sites/49487), but when you're editing `containers/mail-receiver.yml`, change the `base_image` setting to be `womble/discourse-mail-receiver:arm64`.

Note that the `SOCKETEE_RELAY_SOCKET` configuration environment variable is not (yet) supported; if you try to set it, the `mail-receiver` will refuse to start.
If you need this functionality, [create a GitHub issue](https://github.com/mpalmer/discourse-mail-receiver/issues/new) and I'll add support for it.


# Installation and Configuration

Minimal configuration requires you to specify the domain you're receiving
mail for, and how to connect to your Discourse instance (URL, API key, etc).
This involves setting the following environment variables:

* `MAIL_DOMAIN` -- the domain name(s) to accept mail for and relay to
  Discourse.  Any number of space-separated domain names can be listed here.

* `DISCOURSE_BASE_URL` -- the base URL for this Discourse instance.
  This will be whatever your Discourse site URL is. For example,
  `https://discourse.example.com`. If you're running a subfolder setup,
  be sure to account for that (ie `https://example.com/forum`).

* `DISCOURSE_API_KEY` -- the API key which will be used to authenticate to
  Discourse in order to submit mail.  The value to use is shown in the "API"
  tab of the site admin dashboard.

* `DISCOURSE_API_USERNAME` -- (optional) the user whose identity and
  permissions will be used to make requests to the Discourse API.  This
  defaults to `system` and should be OK for 99% of cases.  The remaining 1%
  of times is where someone has (ill-advisedly) renamed the `system` user in
  Discourse.

For a straightforward setup, the above environment variables *should* be
enough to get you up and running.  If you have a desire for a more
complicated setup, the following subsections may provide you with the power
you need.


## Customised Postfix configuration

You can setup any Postfix configuration variables you need by setting env
vars of the form `POSTCONF_<var>` with the value of the variable you want.
For example, if you wanted to add a pre-delivery milter, you might use:

    -e POSTCONF_smtpd_milters=192.0.2.42:12345


## Blacklisting sender domains

The `BLACKLISTED_SENDER_DOMAINS` environment variable accepts a
space-separated list of domain names.  Mail messages from these senders will
be fast-failed with SMTP code 554.


## Syslog integration

Postfix loves to log everything to syslog.  In fact, that's really all it
supports.  Since, by default, Docker is not known for its superlative
out-of-the-box syslog integration, this container runs a tiny script which
reads all syslog data and dumps it to the container's `stderr` (which is
then examinable by `docker logs`).

If, by some chance, you want to process your Postfix logs more extensively,
you're out of luck for the moment, because I haven't added socketee support for arm64 yet.
If you're using `SOCKETEE_RELAY_SOCKET`, [create an issue](https://github.com/mpalmer/discourse-mail-receiver/issues/new) and I'll see what I can do.


# Theory of Operation

Every e-mail that is received is delivered to a custom `discourse` service.
That service, which is a small Ruby program, makes a POST request to the
admin interface on the specified URL (`DISCOURSE_BASE_URL`), with the key
and username specified.  Discourse itself stands ready to receive that
e-mail and process it into the discussion, in exactly the same way as an
e-mail received via POP3 polling.

Before delivery to the `discourse` service, a Postfix policy handler runs,
asks Discourse if either the sender and/or recipient are invalid, and if so,
rejects the incoming mail during the SMTP transaction, to prevent Discourse
later sending out reply emails due to incoming spam ("backscatter").
Legitimate users will be notified of the failure by their MTA, and obvious
spam just gets dropped without reply. This step is just about being a good
citizen of the Internet and not full spam filtering.

### Development Note

When changing files in the lib/ directory, make sure to publish a new rubygems
version once you are done by bumping the version in discourse_mail_receiver.gemspec
and tagging a version starting with `v` in git e.g. `v1.0.4`, then push.
