import React from 'react';
import Chatbot from './pages/Chatbot';
import { Navbar, useConfig } from "nextra-theme-docs";
import { useRouter } from "next/router";

export default {
    head() {
        const { asPath, defaultLocale, locale } = useRouter();
        const { frontMatter } = useConfig();
        const url =
            'https://feds201.com' +
            (defaultLocale === locale ? asPath : `/${locale}${asPath}`);

        return (
            <>
                <meta property="og:url" content={url} />
                <meta property="og:title" content={frontMatter.title || 'FEDS201'} />
                <meta property="og:image" content={frontMatter.image || 'https://i.imgur.com/GmdZ72B.png'}                 />
                <meta property="og:description" content={frontMatter.description || 'FEDS201'}/>
                <meta name="titleSuffix" content="FEDS201" />
                <meta name="description" content="FEDS201" />
                <link rel="icon" href="https://i.imgur.com/GmdZ72B.png" />
                <meta name="viewport" content="width=device-width, initial-scale=1.0" />
                <meta name="twitter:card" content="summary_large_image" />
                <meta name="twitter:site" content="ig" />
                <meta name="msapplication-TileColor" content="#ffffff" />
                <meta name="theme-color" content="#ffffff" />
                <meta name="google-site-verification" content="0LNTJPoseM_CflO4_VtHt5-HsjPSnKEunUGr7-APSZI" />            

                         </>
        );
    },

    logo: (
        <>
            <img
                style={{ borderRadius: '50%', marginTop: '10px' }}
                src="https://i.imgur.com/GmdZ72B.png"
                alt="FEDS201"
                width="30"
                height="30"
            />
            <span>&nbsp;</span>
            <span>&nbsp;</span>
<strong>FEDS  Operational Manual</strong>        </>
    ),

    project: {
        link: 'https://github.com/feds201/FEDS-Handbook',


    },

    chat: {
        link: 'https://feds-handbook.vercel.app/Chatbot',
    },

    docsRepositoryBase : 'https://github.com/feds201/FEDS-Handbook/tree/main',



    footer: {
        text: (
            <div>
                <span>
                    <a href="https://feds201.com" target="_blank" rel="noopener noreferrer">
                        FEDS201 <span style={{ color: '#888' }}></span>
                    </a>
                    {new Date().getFullYear()} ©{' '}
                    <a href="https://rhs-csclub.vercel.app" target="_blank" rel="noopener noreferrer">
                        CS-Club
                    </a>
                </span>
            </div>
        ),
    },
  
    useNextSeoProps() {
        const { asPath } = useRouter()
        if (asPath !== '/') {
          return {
            titleTemplate: '%s – FEDS201'
          }
        }
      },

      sidebar: {
        defaultMenuCollapseLevel: 1,
        autoCollapse: true,
        toggleButton: true,
    },


};
