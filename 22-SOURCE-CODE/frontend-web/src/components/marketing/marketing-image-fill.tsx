import Image from "next/image";

// CC-58 — Image fitted into a fixed-height card photo panel. Used inside
// the existing card slots (StakeholderSolutionCard, TransportServiceCard)
// where the visual area has its own height and we need the image to crop
// gracefully via object-cover. Server-renderable, pure presentational.

interface Props {
  src: string;
  alt: string;
  sizes?: string;
  priority?: boolean;
  className?: string;
}

export function MarketingImageFill({
  src,
  alt,
  sizes,
  priority = false,
  className = "",
}: Props) {
  return (
    <Image
      src={src}
      alt={alt}
      fill
      sizes={sizes ?? "(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 380px"}
      priority={priority}
      className={`object-cover ${className}`}
    />
  );
}
