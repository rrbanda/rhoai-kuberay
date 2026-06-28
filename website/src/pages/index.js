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
        <h1 className="hero__title">{siteConfig.title}</h1>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link className="button button--secondary button--lg" to="/docs/01-overview">
            Start the Workshop
          </Link>
        </div>
      </div>
    </header>
  );
}

const features = [
  {
    title: 'Platform Admin Path',
    description: 'Configure RHOAI, enable KubeRay and Kueue, set up quota management, and prepare the cluster for data scientists.',
    link: '/docs/03-platform-setup',
  },
  {
    title: 'Deploy Ray Clusters',
    description: 'Deploy RayClusters with Kustomize manifests, understand mTLS and pod architecture, and verify with distributed tasks.',
    link: '/docs/04-raycluster',
  },
  {
    title: 'Submit Ray Jobs',
    description: 'Run ephemeral fire-and-forget jobs or iterate quickly on existing clusters. Learn Kueue admission lifecycle.',
    link: '/docs/05-rayjob',
  },
  {
    title: 'CodeFlare SDK',
    description: 'Use the Python SDK from Jupyter notebooks to create clusters and submit jobs without writing Kubernetes YAML.',
    link: '/docs/06-codeflare-sdk',
  },
];

function Feature({title, description, link}) {
  return (
    <div className={clsx('col col--3')}>
      <div className="padding-horiz--md padding-vert--lg">
        <h3><Link to={link}>{title}</Link></h3>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function Home() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout title="Home" description={siteConfig.tagline}>
      <HomepageHeader />
      <main>
        <section className={styles.features}>
          <div className="container">
            <div className="row">
              {features.map((props, idx) => (
                <Feature key={idx} {...props} />
              ))}
            </div>
          </div>
        </section>
        <section className="container padding-vert--xl">
          <h2>Tested On</h2>
          <table>
            <thead>
              <tr>
                <th>Component</th>
                <th>Version</th>
              </tr>
            </thead>
            <tbody>
              <tr><td>OpenShift Container Platform</td><td>4.18+</td></tr>
              <tr><td>Red Hat OpenShift AI</td><td>3.4.1</td></tr>
              <tr><td>KubeRay Operator</td><td>1.4.2 (RHOAI-managed)</td></tr>
              <tr><td>Red Hat build of Kueue</td><td>1.2</td></tr>
              <tr><td>Ray Image</td><td><code>quay.io/modh/ray:2.47.1-py311-cu121</code></td></tr>
            </tbody>
          </table>
        </section>
      </main>
    </Layout>
  );
}
