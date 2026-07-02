import React from 'react';
import ModuleCard from '../ModuleCard';
import type {Tier} from '../Badge';

interface Module {
  name: string;
  description: string;
  tier: Tier;
  icon: string;
  iconBg: string;
  link: string;
}

const MODULES: Module[] = [
  {
    name: 'MinusORM',
    description: 'ORM completo com RTTI, queries fluentes, Unit of Work e Change Tracking.',
    tier: 'free', icon: 'database', iconBg: '#E07A5F', link: '/docs/orm/',
  },
  {
    name: 'MinusMigrator',
    description: 'Migração versionada de schema via CLI, GUI e DLL com suporte a diff automático.',
    tier: 'free', icon: 'arrow-up-bold-box', iconBg: '#3D5A80', link: '/docs/migrator/',
  },
  {
    name: 'MinusCLI',
    description: 'CLI de scaffolding para gerar entidades, APIs e projetos em segundos.',
    tier: 'free', icon: 'console', iconBg: '#4A7C59', link: '/docs/cli/',
  },
  {
    name: 'MinusFeatureFlags',
    description: 'Feature flags com rollout percentual, A/B testing, SSE e REST API.',
    tier: 'pro', icon: 'toggle-switch', iconBg: '#7C6A5E', link: '/docs/modules/FeatureFlags/',
  },
  {
    name: 'MinusMessaging',
    description: 'Message bus multi-provider com retry, circuit breaker, sagas e outbox pattern.',
    tier: 'pro', icon: 'message-flash', iconBg: '#5C4F43', link: '/docs/messaging/',
  },
  {
    name: 'MinusExtensions',
    description: 'Integrações prontas para Horse, JWT e bibliotecas de terceiros.',
    tier: 'pro', icon: 'puzzle', iconBg: '#6B705C', link: '/docs/extensions/',
  },
  {
    name: 'MinusTelemetry',
    description: 'Tracing e logging estruturado no padrão OpenTelemetry.',
    tier: 'enterprise', icon: 'chart-timeline-variant', iconBg: '#C68D5E', link: '/docs/telemetry/',
  },
  {
    name: 'MinusAI',
    description: 'Agentes inteligentes e servidor MCP (Model Context Protocol) para Delphi.',
    tier: 'enterprise', icon: 'robot', iconBg: '#92400E', link: '/docs/ai/',
  },
];

export default function ModuleGrid(): React.ReactElement {
  return (
    <div className="module-grid">
      {MODULES.map((m) => (
        <ModuleCard key={m.name} {...m} />
      ))}
    </div>
  );
}
