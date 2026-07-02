import React from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import Badge from '../components/Badge';

interface PricingPlan {
  name: string;
  price: string;
  period: string;
  license: string;
  devs: string;
  badge: 'free' | 'pro' | 'enterprise';
  highlighted?: boolean;
  features: {name: string; included: boolean}[];
}

const PLANS: PricingPlan[] = [
  {
    name: 'Free', price: 'R$ 0', period: '', license: 'MIT', devs: '1 desenvolvedor',
    badge: 'free',
    features: [
      {name: 'MinusORM (SQLite)', included: true},
      {name: 'MinusORM (7 bancos)', included: false},
      {name: 'MinusMigrator', included: true},
      {name: 'MinusCLI', included: true},
      {name: 'MinusMessaging', included: false},
      {name: 'MinusExtensions', included: false},
      {name: 'MinusFeatureFlags', included: false},
      {name: 'MinusTelemetry', included: false},
      {name: 'MinusAI', included: false},
    ],
  },
  {
    name: 'Pro', price: 'R$ 197', period: '/ano', license: 'Perpétua', devs: '1 desenvolvedor',
    badge: 'pro', highlighted: true,
    features: [
      {name: 'MinusORM (SQLite)', included: true},
      {name: 'MinusORM (7 bancos)', included: true},
      {name: 'MinusMigrator', included: true},
      {name: 'MinusCLI', included: true},
      {name: 'MinusMessaging', included: true},
      {name: 'MinusExtensions', included: true},
      {name: 'MinusFeatureFlags', included: true},
      {name: 'MinusTelemetry', included: false},
      {name: 'MinusAI', included: false},
    ],
  },
  {
    name: 'Enterprise', price: 'R$ 497', period: '/ano', license: 'Perpétua', devs: 'até 5 por bloco',
    badge: 'enterprise',
    features: [
      {name: 'MinusORM (SQLite)', included: true},
      {name: 'MinusORM (7 bancos)', included: true},
      {name: 'MinusMigrator', included: true},
      {name: 'MinusCLI', included: true},
      {name: 'MinusMessaging', included: true},
      {name: 'MinusExtensions', included: true},
      {name: 'MinusFeatureFlags', included: true},
      {name: 'MinusTelemetry', included: true},
      {name: 'MinusAI', included: true},
    ],
  },
];

function PricingCard({plan}: {plan: PricingPlan}): React.ReactElement {
  return (
    <div style={{
      border: `1px solid ${plan.highlighted ? 'var(--ifm-color-primary)' : 'var(--ifm-toc-border-color)'}`,
      borderRadius: 'var(--ifm-card-border-radius)',
      padding: '1.5rem',
      background: plan.highlighted ? 'rgba(224,122,95,0.04)' : 'var(--ifm-card-background-color, white)',
      position: 'relative',
    }}>
      {plan.highlighted && (
        <div style={{
          position: 'absolute', top: '-0.75rem', left: '50%', transform: 'translateX(-50%)',
          background: 'var(--ifm-color-primary)', color: 'white',
          padding: '0.2rem 1rem', borderRadius: '2rem', fontSize: '0.75rem', fontWeight: 700,
        }}>
          Mais popular
        </div>
      )}
      <div style={{textAlign: 'center', marginBottom: '1rem'}}>
        <h3 style={{margin: 0}}>{plan.name}</h3>
        <div style={{fontSize: '2rem', fontWeight: 800, margin: '0.5rem 0'}}>
          {plan.price}<span style={{fontSize: '0.9rem', fontWeight: 400, color: 'var(--ifm-color-emphasis-600)'}}>{plan.period}</span>
        </div>
        <div style={{display: 'flex', justifyContent: 'center', gap: '0.5rem', marginBottom: '0.5rem'}}>
          <Badge tier={plan.badge} />
        </div>
        <div style={{fontSize: '0.8rem', color: 'var(--ifm-color-emphasis-600)'}}>{plan.license} &middot; {plan.devs}</div>
      </div>
      <div style={{borderTop: '1px solid var(--ifm-toc-border-color)', paddingTop: '0.75rem'}}>
        {plan.features.map((f) => (
          <div key={f.name} style={{
            display: 'flex', justifyContent: 'space-between', padding: '0.35rem 0',
            fontSize: '0.85rem', opacity: f.included ? 1 : 0.4,
          }}>
            <span>{f.name}</span>
            <span style={{color: f.included ? 'var(--ifm-color-primary)' : undefined}}>
              {f.included ? '✓' : '—'}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

export default function Pricing(): React.ReactElement {
  return (
    <Layout title="Planos" description="Compare os planos Free, Pro e Enterprise do MinusFrameWork.">
      <main className="container" style={{padding: '2rem 1rem', maxWidth: '900px', margin: '0 auto'}}>
        <h1 style={{textAlign: 'center'}}>Planos</h1>

        <div style={{
          display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '1rem', margin: '2rem 0',
        }}>
          {PLANS.map((p) => <PricingCard key={p.name} plan={p} />)}
        </div>

        <section style={{marginTop: '3rem'}}>
          <h2>Free (MIT)</h2>
          <p>Baixe e use sem restrições.</p>
          <Link className="button button--primary" to="https://github.com/GabrielFerreiraMendes/minusframework/releases/latest">
            Download Free
          </Link>
        </section>

        <section style={{marginTop: '2rem'}}>
          <h2>Pro (em breve)</h2>
          <p>Inclui ORM multi-banco, Mensageria, Feature Flags e Extensions.</p>
          <ul>
            <li><strong>R$ 197/ano</strong> por desenvolvedor</li>
            <li>Licença perpétua</li>
            <li>12 meses de atualizações e suporte</li>
            <li>Renovação anual opcional</li>
          </ul>
        </section>

        <section style={{marginTop: '2rem'}}>
          <h2>Enterprise (em breve)</h2>
          <p>Tudo do Pro mais Telemetria, AI/MCP Server e suporte prioritário.</p>
          <ul>
            <li><strong>R$ 497/ano</strong> por bloco de até 5 desenvolvedores</li>
            <li>Licença perpétua</li>
            <li>12 meses de atualizações e suporte</li>
            <li>Renovação anual opcional</li>
          </ul>
        </section>

        <section style={{marginTop: '2rem'}}>
          <h2>Dúvidas Frequentes</h2>
          <details><summary><strong>Preciso pagar todo ano?</strong></summary>
            Não. As licenças Pro e Enterprise são <strong>perpétuas</strong> — o software continua funcionando mesmo sem renovar.
          </details>
          <details><summary><strong>Posso usar em mais de uma máquina?</strong></summary>
            Sim, desde que o mesmo desenvolvedor. Cada licença é por desenvolvedor, não por máquina.
          </details>
          <details><summary><strong>Posso atualizar do Free para o Pro?</strong></summary>
            Sim. Basta adquirir a chave Pro e aplicar no mesmo instalador.
          </details>
        </section>
      </main>
    </Layout>
  );
}
