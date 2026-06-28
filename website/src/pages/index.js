import React from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import styles from './index.module.css';

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <p className={styles.heroEyebrow}>Red Hat OpenShift AI 3.4 Workshop</p>
        <h1 className="hero__title">{siteConfig.title}</h1>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link className="button button--secondary button--lg" to="/docs/01-overview">
            Start the Workshop
          </Link>
          <Link className="button button--outline button--lg" style={{color: '#fff', borderColor: 'rgba(255,255,255,0.5)'}} href="https://github.com/rrbanda/rhoai-kuberay">
            View on GitHub
          </Link>
        </div>
      </div>
    </header>
  );
}

const features = [
  {
    icon: '&#9881;',
    title: 'Platform Setup',
    description: 'Enable KubeRay and Kueue in the DataScienceCluster, configure quota management, and prepare namespaces for data scientists.',
    link: '/docs/03-platform-setup',
    audience: 'Admin',
  },
  {
    icon: '&#9729;',
    title: 'Ray Clusters',
    description: 'Deploy RayClusters with Kustomize, understand the mTLS + kube-rbac-proxy pod architecture, and validate with distributed tasks.',
    link: '/docs/04-raycluster',
    audience: 'Admin / DS',
  },
  {
    icon: '&#9889;',
    title: 'Ray Jobs',
    description: 'Submit ephemeral fire-and-forget jobs or iterate quickly on existing clusters. Master the Kueue admission lifecycle.',
    link: '/docs/05-rayjob',
    audience: 'Admin / DS',
  },
  {
    icon: '&#128218;',
    title: 'CodeFlare SDK',
    description: 'Create clusters and submit jobs from Jupyter notebooks using Python. No Kubernetes YAML required.',
    link: '/docs/06-codeflare-sdk',
    audience: 'Data Scientist',
  },
];

const versions = [
  { label: 'OCP 4.19+', color: '#cc0000' },
  { label: 'RHOAI 3.4.1', color: '#0066cc' },
  { label: 'KubeRay 1.4.2', color: '#2e8b57' },
  { label: 'Kueue 1.2', color: '#cc7a00' },
  { label: 'Ray 2.47.1', color: '#6a0dad' },
];

function Feature({icon, title, description, link, audience}) {
  return (
    <div className="col col--3">
      <div className="feature-card">
        <span className="feature-icon" dangerouslySetInnerHTML={{__html: icon}} />
        <h3><Link to={link}>{title}</Link></h3>
        <p>{description}</p>
        <span className={styles.audienceBadge}>{audience}</span>
      </div>
    </div>
  );
}

const modules = [
  { num: '01', title: 'Overview', desc: 'Architecture, CRDs, workflows', to: '/docs/01-overview' },
  { num: '02', title: 'Prerequisites', desc: 'Operators, versions, verification', to: '/docs/02-prerequisites' },
  { num: '03', title: 'Platform Setup', desc: 'DSC, Kueue, namespaces', to: '/docs/03-platform-setup' },
  { num: '04', title: 'RayCluster', desc: 'Deploy, verify, dashboard', to: '/docs/04-raycluster' },
  { num: '05', title: 'RayJob', desc: 'Ephemeral and existing-cluster', to: '/docs/05-rayjob' },
  { num: '06', title: 'CodeFlare SDK', desc: 'Python SDK from notebooks', to: '/docs/06-codeflare-sdk' },
  { num: '07', title: 'Troubleshooting', desc: 'Known issues, recovery', to: '/docs/07-troubleshooting' },
];

export default function Home() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout title="Home" description={siteConfig.tagline}>
      <HomepageHeader />
      <main>
        {/* Version badges */}
        <section className="container" style={{textAlign: 'center', padding: '2rem 0 0'}}>
          <div className="version-badges">
            {versions.map((v, i) => (
              <span key={i} className="version-badge">
                <span style={{
                  width: 10, height: 10, borderRadius: '50%',
                  backgroundColor: v.color, display: 'inline-block'
                }} />
                {v.label}
              </span>
            ))}
          </div>
        </section>

        {/* Feature cards */}
        <section className={styles.features}>
          <div className="container">
            <h2 style={{textAlign: 'center', marginBottom: '2rem'}}>What You Will Learn</h2>
            <div className="row">
              {features.map((props, idx) => (
                <Feature key={idx} {...props} />
              ))}
            </div>
          </div>
        </section>

        {/* Module list */}
        <section className="section-alt">
          <div className="container">
            <h2 style={{textAlign: 'center', marginBottom: '2rem'}}>Workshop Modules</h2>
            <div className="row">
              {modules.map((m, i) => (
                <div key={i} className="col col--4" style={{marginBottom: '1rem'}}>
                  <Link to={m.to} style={{textDecoration: 'none', color: 'inherit'}}>
                    <div className="feature-card" style={{display: 'flex', alignItems: 'center', gap: '1rem', padding: '1rem 1.25rem'}}>
                      <span style={{
                        fontSize: '1.5rem', fontWeight: 800, opacity: 0.3,
                        minWidth: '2rem', textAlign: 'center'
                      }}>{m.num}</span>
                      <div>
                        <strong>{m.title}</strong>
                        <br />
                        <span style={{fontSize: '0.85rem', opacity: 0.7}}>{m.desc}</span>
                      </div>
                    </div>
                  </Link>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Quick start */}
        <section className="container padding-vert--xl">
          <h2 style={{textAlign: 'center'}}>Quick Start</h2>
          <div style={{maxWidth: 700, margin: '0 auto'}}>
            <pre style={{borderRadius: 12, padding: '1.5rem'}}>
{`# 1. Enable KubeRay (admin)
oc patch datasciencecluster default-dsc --type='merge' \\
  -p '{"spec":{"components":{"ray":{"managementState":"Managed"},
  "kueue":{"managementState":"Unmanaged"}}}}'

# 2. Apply Kueue resources + create namespace
oc apply -k manifests/platform/
oc apply -k manifests/base/

# 3. Deploy and test
oc apply -k manifests/raycluster/
./scripts/fix-auth.sh ray-demo demo-cluster
./scripts/test-cluster.sh ray-demo demo-cluster`}
            </pre>
          </div>
        </section>
      </main>
    </Layout>
  );
}
