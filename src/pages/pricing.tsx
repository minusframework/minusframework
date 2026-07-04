import React, { useState } from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import Badge from '../components/Badge';

interface PricingPlan {
  name: string;
  price: { monthly: number; yearly: number };
  license: string;
  devs: string;
  badge: 'free' | 'pro' | 'enterprise';
  highlighted?: boolean;
  features: { name: string; included: boolean }[];
}

const PLANS: PricingPlan[] = [
  {
    name: 'Free', price: { monthly: 0, yearly: 0 }, license: 'MIT', devs: '1 desenvolvedor',
    badge: 'free',
    features: [
      { name: 'MinusORM (SQLite)', included: true },
      { name: 'MinusORM (7 bancos)', included: false },
      { name: 'MinusMigrator', included: true },
      { name: 'MinusCLI', included: true },
      { name: 'MinusMessaging', included: false },
      { name: 'MinusExtensions', included: false },
      { name: 'MinusFeatureFlags', included: false },
      { name: 'MinusTelemetry', included: false },
      { name: 'MinusAI', included: false },
    ],
  },
  {
    name: 'Pro', price: { monthly: 29, yearly: 197 }, license: 'Perpétua', devs: '1 desenvolvedor',
    badge: 'pro', highlighted: true,
    features: [
      { name: 'MinusORM (SQLite)', included: true },
      { name: 'MinusORM (7 bancos)', included: true },
      { name: 'MinusMigrator', included: true },
      { name: 'MinusCLI', included: true },
      { name: 'MinusMessaging', included: true },
      { name: 'MinusExtensions', included: true },
      { name: 'MinusFeatureFlags', included: true },
      { name: 'MinusTelemetry', included: false },
      { name: 'MinusAI', included: false },
    ],
  },
  {
    name: 'Enterprise', price: { monthly: 69, yearly: 497 }, license: 'Perpétua', devs: 'até 5 por bloco',
    badge: 'enterprise',
    features: [
      { name: 'MinusORM (SQLite)', included: true },
      { name: 'MinusORM (7 bancos)', included: true },
      { name: 'MinusMigrator', included: true },
      { name: 'MinusCLI', included: true },
      { name: 'MinusMessaging', included: true },
      { name: 'MinusExtensions', included: true },
      { name: 'MinusFeatureFlags', included: true },
      { name: 'MinusTelemetry', included: true },
      { name: 'MinusAI', included: true },
    ],
  },
];

function formatPrice(price: number): string {
  if (price === 0) return 'Grátis';
  return `R$ ${price}`;
}

export default function Pricing(): React.ReactElement {
  const [yearly, setYearly] = useState(true);
  return (
    <Layout title="Planos" description="Compare os planos Free, Pro e Enterprise do MinusFrameWork.">
      <main className="container" style={{ padding: '2rem 1rem', maxWidth: '1000px', margin: '0 auto' }}>
        <h1 style={{ textAlign: 'center', marginBottom: '0.5rem' }}>Planos</h1>
        <p style={{ textAlign: 'center', color: 'var(--ifm-color-emphasis-600)', marginBottom: '1.5rem' }}>
          Escolha o plano ideal para sua equipe
        </p>

        <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '0.75rem', marginBottom: '2rem' }}>
          <span style={{ fontSize: '0.9rem', color: !yearly ? 'var(--ifm-color-primary)' : 'var(--ifm-color-emphasis-600)', fontWeight: yearly ? 400 : 700 }}>Mensal</span>
          <label style={{ position: 'relative', display: 'inline-block', width: '48px', height: '26px' }}>
            <input type="checkbox" checked={yearly} onChange={() => setYearly(!yearly)}
              style={{ opacity: 0, width: 0, height: 0 }} />
            <span style={{
              position: 'absolute', cursor: 'pointer', inset: 0,
              background: yearly ? 'var(--ifm-color-primary)' : '#ccc',
              borderRadius: '26px', transition: 'background 0.2s',
            }}>
              <span style={{
                position: 'absolute', content: '', height: '20px', width: '20px',
                left: yearly ? '26px' : '2px', bottom: '3px',
                background: 'white', borderRadius: '50%', transition: 'left 0.2s',
              }} />
            </span>
          </label>
          <span style={{ fontSize: '0.9rem', color: yearly ? 'var(--ifm-color-primary)' : 'var(--ifm-color-emphasis-600)', fontWeight: yearly ? 700 : 400 }}>
            Anual <span style={{ fontSize: '0.75rem', color: 'var(--ifm-color-primary)', fontWeight: 600 }}>(2 meses grátis)</span>
          </span>
        </div>

        <div style={{
          display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '1rem', margin: '2rem 0',
        }}>
          {PLANS.map((p) => {
            const price = yearly ? p.price.yearly : p.price.monthly;
            const period = yearly ? (price > 0 ? '/ano' : '') : (price > 0 ? '/mês' : '');
            return (
              <div key={p.name} className={`pricing-card${p.highlighted ? ' highlighted' : ''}`} style={{
                border: `1px solid ${p.highlighted ? 'var(--ifm-color-primary)' : 'var(--ifm-toc-border-color)'}`,
                borderRadius: 'var(--ifm-card-border-radius)',
                padding: '1.5rem',
                background: p.highlighted ? 'rgba(224,122,95,0.04)' : 'var(--ifm-card-background-color, white)',
                position: 'relative',
              }}>
                {p.highlighted && <div className="pricing-badge">Mais popular</div>}
                <div style={{ textAlign: 'center', marginBottom: '1rem' }}>
                  <h3 style={{ margin: 0 }}>{p.name}</h3>
                  <div style={{ fontSize: '2rem', fontWeight: 800, margin: '0.5rem 0' }}>
                    {formatPrice(price)}<span style={{ fontSize: '0.9rem', fontWeight: 400, color: 'var(--ifm-color-emphasis-600)' }}>{period}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'center', gap: '0.5rem', marginBottom: '0.5rem' }}>
                    <Badge tier={p.badge} />
                  </div>
                  <div style={{ fontSize: '0.8rem', color: 'var(--ifm-color-emphasis-600)' }}>{p.license} &middot; {p.devs}</div>
                </div>
                <div style={{ borderTop: '1px solid var(--ifm-toc-border-color)', paddingTop: '0.75rem' }}>
                  {p.features.map((f) => (
                    <div key={f.name} style={{
                      display: 'flex', justifyContent: 'space-between', padding: '0.35rem 0',
                      fontSize: '0.85rem', opacity: f.included ? 1 : 0.4,
                    }}>
                      <span>{f.name}</span>
                      <span style={{ color: f.included ? 'var(--ifm-color-primary)' : undefined }}>
                        {f.included ? '✓' : '—'}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            );
          })}
        </div>

        <section style={{ marginTop: '3rem' }}>
          <h2>Free (MIT)</h2>
          <p>Baixe e use sem restrições.</p>
          <Link className="button button--primary" to="https://github.com/GabrielFerreiraMendes/minusframework/releases/latest">
            Download Free
          </Link>
        </section>

        <section style={{ marginTop: '2rem' }}>
          <h2>Pro (em breve)</h2>
          <p>Inclui ORM multi-banco, Mensageria, Feature Flags e Extensions.</p>
          <ul>
            <li><strong>R$ 197/ano</strong> por desenvolvedor</li>
            <li>Licença perpétua</li>
            <li>12 meses de atualizações e suporte</li>
            <li>Renovação anual opcional</li>
          </ul>
        </section>

        <section style={{ marginTop: '2rem' }}>
          <h2>Enterprise (em breve)</h2>
          <p>Tudo do Pro mais Telemetria, AI/MCP Server e suporte prioritário.</p>
          <ul>
            <li><strong>R$ 497/ano</strong> por bloco de até 5 desenvolvedores</li>
            <li>Licença perpétua</li>
            <li>12 meses de atualizações e suporte</li>
            <li>Renovação anual opcional</li>
          </ul>
        </section>

        <section style={{ marginTop: '2rem' }}>
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
