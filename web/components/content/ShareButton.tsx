'use client';

import { useState, useEffect, useRef } from 'react';
import { Share2, Link as LinkIcon, Check, X, Twitter, Facebook, Linkedin, MessageCircle, Mail } from 'lucide-react';

type ShareProps = {
  title: string;
  url: string;
  text?: string;
  /** Variant: 'inline' shows button only, 'sheet' opens floating share sheet */
  variant?: 'inline' | 'sheet';
};

export function ShareButton({ title, url, text, variant = 'inline' }: ShareProps) {
  const [open, setOpen] = useState(false);
  const [copied, setCopied] = useState(false);
  const popoverRef = useRef<HTMLDivElement>(null);

  const shareText = text || title;
  const urlEnc = encodeURIComponent(url);
  const textEnc = encodeURIComponent(shareText);
  const titleEnc = encodeURIComponent(title);

  useEffect(() => {
    if (!open) return;
    const onClick = (e: MouseEvent) => {
      if (popoverRef.current && !popoverRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    };
    const onEsc = (e: KeyboardEvent) => { if (e.key === 'Escape') setOpen(false); };
    document.addEventListener('mousedown', onClick);
    document.addEventListener('keydown', onEsc);
    return () => {
      document.removeEventListener('mousedown', onClick);
      document.removeEventListener('keydown', onEsc);
    };
  }, [open]);

  const handleNative = async () => {
    if (typeof navigator !== 'undefined' && (navigator as any).share) {
      try {
        await (navigator as any).share({ title, text: shareText, url });
        setOpen(false);
      } catch {}
    } else {
      setOpen(!open);
    }
  };

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(url);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {}
  };

  const options = [
    { name: 'Twitter / X', icon: <Twitter size={14} />, href: `https://twitter.com/intent/tweet?text=${textEnc}&url=${urlEnc}`, color: 'hover:bg-black hover:text-white' },
    { name: 'Facebook', icon: <Facebook size={14} />, href: `https://www.facebook.com/sharer/sharer.php?u=${urlEnc}`, color: 'hover:bg-blue-600 hover:text-white' },
    { name: 'LinkedIn', icon: <Linkedin size={14} />, href: `https://www.linkedin.com/sharing/share-offsite/?url=${urlEnc}`, color: 'hover:bg-blue-700 hover:text-white' },
    { name: 'WhatsApp', icon: <MessageCircle size={14} />, href: `https://wa.me/?text=${textEnc}%20${urlEnc}`, color: 'hover:bg-green-600 hover:text-white' },
    { name: 'Email', icon: <Mail size={14} />, href: `mailto:?subject=${titleEnc}&body=${textEnc}%20${urlEnc}`, color: 'hover:bg-sage-600 hover:text-white' },
  ];

  return (
    <div className="relative inline-block">
      <button
        onClick={handleNative}
        className="inline-flex items-center gap-2 px-4 py-2 rounded-full text-sm bg-paper border border-ink/10 text-ink/70 hover:border-ink/30 hover:text-ink transition-colors"
        aria-label="Share"
      >
        <Share2 size={14} />
        Share
      </button>

      {open && (
        <div
          ref={popoverRef}
          className="absolute right-0 top-full mt-2 w-64 card-quiet p-2 z-50 animate-fade-in"
          role="dialog"
          aria-label="Share options"
        >
          <div className="flex items-center justify-between px-3 py-2 mb-1">
            <span className="text-xs tracking-widest uppercase text-ink/40">Share to</span>
            <button onClick={() => setOpen(false)} className="text-ink/40 hover:text-ink" aria-label="Close">
              <X size={14} />
            </button>
          </div>
          <div className="space-y-0.5">
            {options.map(opt => (
              <a
                key={opt.name}
                href={opt.href}
                target="_blank"
                rel="noopener noreferrer"
                onClick={() => setOpen(false)}
                className={`flex items-center gap-3 px-3 py-2 rounded-lg text-sm text-ink/80 transition-colors ${opt.color}`}
              >
                {opt.icon}
                {opt.name}
              </a>
            ))}
            <button
              onClick={copy}
              className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-sm text-ink/80 hover:bg-sage-100 transition-colors"
            >
              {copied ? <Check size={14} className="text-green-600" /> : <LinkIcon size={14} />}
              {copied ? 'Copied!' : 'Copy link'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
