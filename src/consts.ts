// Site-wide content. Edit here; components read from this file.

export const SITE_TITLE = 'Trisatya';
export const SITE_DESCRIPTION =
	'Backend engineer. I build services and run a small cloud of my own: Keycloak, Grafana and an MCP workbench on one VPS.';

export const PERSON = {
	name: 'Trisatya',
	fullName: 'Trisatya Elisa Mintar Manurung',
	role: 'Backend engineer',
	location: 'Indonesia',
	tagline: 'I build backend systems, and I run my own small cloud to learn how they behave in production.',
};

export const LINKS = {
	github: 'https://github.com/trisatyaelisa-dev',
	// linkedin: 'https://www.linkedin.com/in/<your-handle>',
};

export type ServiceKey = 'grafana' | 'workbench' | 'keycloak';

export const SERVICES: {
	key: ServiceKey;
	name: string;
	host: string;
	url: string;
	kicker: string;
	blurb: string;
	tags: string[];
}[] = [
	{
		key: 'grafana',
		name: 'Grafana',
		host: 'grafana.trisatya.dev',
		url: 'https://grafana.trisatya.dev',
		kicker: 'Observability',
		blurb:
			'Metrics from Prometheus, logs from Loki shipped by Alloy, and the official Keycloak dashboards. Sign-in goes through my Keycloak.',
		tags: ['Prometheus', 'Loki', 'Alloy', 'Grafana 13'],
	},
	{
		key: 'workbench',
		name: 'workbench',
		host: 'mcp.trisatya.dev',
		url: 'https://mcp.trisatya.dev',
		kicker: 'MCP tool aggregator',
		blurb:
			'One MCP endpoint for AI agents in front of many integrations, with per-user OAuth and encrypted tokens. A self-hosted fork of an MIT project.',
		tags: ['MCP', 'Fastify', 'SQLite', 'OAuth 2.1'],
	},
	{
		key: 'keycloak',
		name: 'Keycloak',
		host: 'auth.trisatya.dev',
		url: 'https://auth.trisatya.dev',
		kicker: 'Single sign-on',
		blurb:
			'One account for every app here. OIDC clients for Grafana and workbench, role mapping, OTP for admins, nightly pg_dump backups.',
		tags: ['Keycloak 26', 'PostgreSQL 18', 'OIDC', 'TOTP'],
	},
];

export const TOOLBOX = ['Go', 'Java / Quarkus', 'Kafka', 'PostgreSQL', 'MongoDB', 'Elasticsearch', 'Keycloak', 'gRPC', 'Docker', 'Nginx', 'GitHub Actions', 'Grafana stack'];
