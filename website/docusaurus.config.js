// @ts-check

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'KubeRay on RHOAI',
  tagline: 'A hands-on workshop for distributed Ray workloads on Red Hat OpenShift AI',
  favicon: 'img/favicon.ico',

  url: 'https://rrbanda.github.io',
  baseUrl: '/rhoai-kuberay/',

  organizationName: 'rrbanda',
  projectName: 'rhoai-kuberay',

  onBrokenLinks: 'throw',
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  markdown: {
    mermaid: true,
  },

  themes: ['@docusaurus/theme-mermaid'],

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: './sidebars.js',
          editUrl: 'https://github.com/rrbanda/rhoai-kuberay/tree/main/website/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      navbar: {
        title: 'KubeRay on RHOAI',
        items: [
          {
            type: 'docSidebar',
            sidebarId: 'workshopSidebar',
            position: 'left',
            label: 'Workshop',
          },
          {
            href: 'https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4',
            label: 'RHOAI Docs',
            position: 'right',
          },
          {
            href: 'https://github.com/rrbanda/rhoai-kuberay',
            label: 'GitHub',
            position: 'right',
          },
        ],
      },
      footer: {
        style: 'dark',
        links: [
          {
            title: 'Workshop',
            items: [
              { label: 'Overview', to: '/docs/01-overview' },
              { label: 'Prerequisites', to: '/docs/02-prerequisites' },
              { label: 'Platform Setup', to: '/docs/03-platform-setup' },
              { label: 'RayCluster', to: '/docs/04-raycluster' },
              { label: 'Troubleshooting', to: '/docs/07-troubleshooting' },
            ],
          },
          {
            title: 'Official Docs',
            items: [
              { label: 'RHOAI 3.4', href: 'https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4' },
              { label: 'Distributed Workloads', href: 'https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html-single/working_with_distributed_workloads/' },
              { label: 'KubeRay', href: 'https://github.com/ray-project/kuberay' },
              { label: 'CodeFlare SDK', href: 'https://github.com/project-codeflare/codeflare-sdk' },
            ],
          },
          {
            title: 'More',
            items: [
              { label: 'GitHub', href: 'https://github.com/rrbanda/rhoai-kuberay' },
              { label: 'Red Hat Developer', href: 'https://developers.redhat.com/' },
            ],
          },
        ],
        copyright: `Built with Docusaurus. Not affiliated with Red Hat, Inc.`,
      },
      mermaid: {
        theme: { light: 'neutral', dark: 'dark' },
      },
      prism: {
        theme: require('prism-react-renderer').themes.github,
        darkTheme: require('prism-react-renderer').themes.dracula,
        additionalLanguages: ['bash', 'yaml', 'python', 'json'],
      },
    }),
};

module.exports = config;
