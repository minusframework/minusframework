import React from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import HighlightCards from '../components/HighlightCards';
import ModuleGrid from '../components/ModuleGrid';

const WHY_MINUS = [
  {
    icon: '\u26A1',
    title: 'Performance',
    desc: 'Componentes Delphi otimizados para aplicações corporativas de alta demanda, com baixo overhead e profiling integrado.',
  },
  {
    icon: '\u{1F9EA}',
    title: 'Modularidade',
    desc: 'Use só o que precisa. Free (MIT) até Enterprise. Cada módulo é independente e testável isoladamente.',
  },
  {
    icon: '\u{1F4CB}',
    title: 'Testabilidade',
    desc: 'Clean Architecture + SOLID + Object Calisthenics. Injeção de dependência, mocks e testes desde o primeiro dia.',
  },
];

export default function Home(): React.ReactElement {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout title="MinusFrameWork" description={siteConfig.tagline}>
      <main>
        <section className="hero">
          <div className="hero__title-block">
            <h1 className="hero__title">
              Framework Delphi<br />
              <span className="gradient-text">moderno e modular</span>
            </h1>
            <p className="hero__tagline">{siteConfig.tagline}</p>
          </div>
          <div className="hero__cta">
            <Link className="button button--primary" to="/docs/getting-started">
              Começar agora →
            </Link>
            <Link className="button button--secondary" to="/pricing">
              Ver planos
            </Link>
          </div>
        </section>

        <section className="container" style={{padding: '3rem 1rem'}}>
          <h2 style={{textAlign: 'center', marginBottom: '2rem'}}>Por que MinusFrameWork?</h2>
          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
            gap: '1.5rem',
            marginBottom: '3rem',
            justifyContent: 'center',
          }}>
            {WHY_MINUS.map((item) => (
              <div key={item.title} className="card" style={{textAlign: 'center', padding: '2rem 1.5rem'}}>
                <div style={{fontSize: '2.5rem', marginBottom: '0.75rem'}}>{item.icon}</div>
                <h3 style={{marginBottom: '0.5rem'}}>{item.title}</h3>
                <p style={{fontSize: '0.9rem', color: 'var(--ifm-color-emphasis-600)', lineHeight: 1.6}}>
                  {item.desc}
                </p>
              </div>
            ))}
          </div>
        </section>

        <section className="container" style={{padding: '0 1rem 2rem'}}>
          <h2 style={{textAlign: 'center', marginBottom: '0.5rem'}}>Módulos gratuitos</h2>
          <p style={{textAlign: 'center', color: 'var(--ifm-color-emphasis-600)', marginBottom: '1.5rem'}}>
            Comece com esses módulos sem custo — licença MIT.
          </p>
          <HighlightCards />

          <h2 style={{textAlign: 'center', marginTop: '3rem', marginBottom: '0.5rem'}}>Ecossistema completo</h2>
          <p style={{textAlign: 'center', color: 'var(--ifm-color-emphasis-600)', marginBottom: '1.5rem'}}>
            Todos os módulos do MinusFrameWork, do Free ao Enterprise.
          </p>
          <ModuleGrid />
        </section>
      </main>
    </Layout>
  );
}
