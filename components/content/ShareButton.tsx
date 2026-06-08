'use client';

import { useState } from 'react';
import { Share2, Copy, Check, Twitter, Facebook, Linkedin } from 'lucide-react';

export function ShareButton({ title, url, text }: { title: string; url: string; text?: string }) {
  const [open, setOpen] = useState(false);
  const [copied, setCopied] = useState(false);

  const share = async () => {
    if (typeof navigator !== 'undefined' && (navigator as any).share) {
      try {
        await (navigator as any).share({ title, text, url });
        return;
      } catch {}
    }
    setOpen(true);
  };

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(url);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {}
  };

  const enc = encodeURIComponent;
  const textEnc = enc(text || title);
  const urlEnc = enc(url);

  return (
    <>
      <button onClick={share} className="inline-flex items-center gap-2 px-4 py-2 rounded-full text-sm bg-paper border border-ink/10 text-ink/70 hover:border-ink/30">
        <Share2 size={14} /> Share
      </button>
      {open && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-ink/30 backdrop-blur-sm" onClick={() => setOpen(false)}>
          <div className="card-quiet max-w-sm w-full p-8" onClick={e => e.stopPropagation()}>
            <h3 className="serif text-xl mb-2">Share this practice</h3>
            <p className="text-sm text-ink/60 mb-6">Send to a friend, post on socials, or copy the link.</p>
            <div className="flex gap-2 mb-4">
              <a href={`https://twitter.com/intent/tweet?text=${textEnc}&url=${urlEnc}`} target="_blank" rel="noopener" className="flex-1 btn-ghost text-sm justify-center">
                <Twitter size={14} /> X
              </a>
              <a href={`https://www.facebook.com/sharer/sharer.php?u=${urlEnc}`} target="_blank" rel="noopener" className="flex-1 btn-ghost text-sm justify-center">
                <Facebook size={14} /> Facebook
              </a>
              <a href={`https://www.linkedin.com/sharing/share-offsite/?url=${urlEnc}`} target="_blank" rel="noopener" className="flex-1 btn-ghost text-sm justify-center">
                <Linkedin size={14} /> LinkedIn
              </a>
            </div>
            <button onClick={copy} className="w-full btn-primary">
              {copied ? <><Check size={14} /> Copied</> : <><Copy size={14} /> Copy link</>}
            </button>
          </div>
        </div>
      )}
    </>
  );
}
