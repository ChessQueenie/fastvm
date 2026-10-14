//! Image catalog and marketplace model.
//!
//! Pure data and pure functions only - no I/O, no Docker. This keeps the
//! marketplace listing and the `docker run` argument builder unit-testable.
//!
//! Keep the desktop/preset/flavor lists in sync with the build matrix in
//! `.github/workflows/build-images.yml`. `scripts/verify-catalog.js` checks it.

use serde::Serialize;

/// Registry prefix for every published image.
pub const REGISTRY: &str = "ghcr.io/cloudcompile/fastvm";

/// Port the streamed desktop listens on inside the container.
pub const DESKTOP_PORT: u16 = 3000;
/// Port the management dashboard listens on inside the container.
pub const DASHBOARD_PORT: u16 = 8099;

/// Every published desktop environment.
pub const DESKTOPS: &[&str] = &[
    "xfce4", "kde", "gnome", "cinnamon", "lxqt", "i3", "budgie", "mate", "lxde",
    "fluxbox", "unity", "enlightenment", "icewm", "awesome", "ukui", "bspwm",
    "gnome-flashback", "wmaker", "herbstluftwm", "jwm", "fvwm", "xmonad", "sugar",
    "dwm", "ratpoison", "blackbox", "pop-os", "pekwm", "spectrwm", "sawfish",
    "openbox", "afterstep", "ctwm", "twm", "nixos", "pearos",
];

/// Every published preset overlay.
pub const PRESETS: &[&str] = &[
    "none", "minimal", "gaming", "development", "office", "content-creation",
];

/// Ultra-minimal single-application images.
pub const SINGLE_APPS: &[&str] = &["browser", "discord", "vscode", "terminal"];

/// Distro-flavor images (each publishes a single `<flavor>-latest` tag).
pub const FLAVORS: &[&str] = &[
    "fastvm-os", "ubuntu-studio", "ubuntu-kylin", "ubuntu-budgie",
    "ubuntu-edubuntu", "xubuntu", "lubuntu", "kubuntu", "ubuntu-mate",
    "ubuntu-unity", "pop-os", "linuxmint", "kali", "parrot", "nixos", "pearos",
];

/// `<desktop>-<preset>-latest`.
pub fn desktop_tag(desktop: &str, preset: &str) -> Result<String, String> {
    if !DESKTOPS.contains(&desktop) {
        return Err(format!("unknown desktop: {desktop}"));
    }
    if !PRESETS.contains(&preset) {
        return Err(format!("unknown preset: {preset}"));
    }
    Ok(format!("{desktop}-{preset}-latest"))
}

/// `<flavor>-latest`.
pub fn flavor_tag(flavor: &str) -> Result<String, String> {
    if !FLAVORS.contains(&flavor) {
        return Err(format!("unknown flavor: {flavor}"));
    }
    Ok(format!("{flavor}-latest"))
}

/// `<name>-latest`.
pub fn single_app_tag(name: &str) -> Result<String, String> {
    if !SINGLE_APPS.contains(&name) {
        return Err(format!("unknown single-app image: {name}"));
    }
    Ok(format!("{name}-latest"))
}

/// Fully-qualified image reference.
pub fn image_ref(tag: &str) -> String {
    format!("{REGISTRY}:{tag}")
}

/// Total published variants (desktop x preset + single-app + flavor).
pub fn variant_count() -> usize {
    DESKTOPS.len() * PRESETS.len() + SINGLE_APPS.len() + FLAVORS.len()
}

/// A marketplace listing.
#[derive(Clone, Debug, Serialize)]
pub struct App {
    /// Image tag, e.g. `pearos-none-latest`.
    pub id: String,
    pub name: String,
    pub tagline: String,
    pub category: String,
    /// `desktop`, `preset`, `flavor`, or `single`.
    pub kind: String,
    pub desktop: Option<String>,
    pub preset: Option<String>,
    pub flavor: Option<String>,
    pub ram: String,
    pub gpu: bool,
    pub featured: bool,
    pub image: String,
}

/// Arguments for a one-click deploy.
#[derive(Clone, Debug, Default)]
pub struct RunSpec {
    pub image: String,
    pub host_port: u16,
    pub dashboard_port: u16,
    pub name: Option<String>,
    pub shm_size: Option<String>,
    pub memory: Option<String>,
    pub cpus: Option<String>,
    pub gpu: bool,
    pub env: Vec<String>,
    pub volumes: Vec<String>,
}

/// Build the `docker run` argument vector (without the leading `docker`).
pub fn build_run_args(spec: &RunSpec) -> Result<Vec<String>, String> {
    if spec.image.is_empty() {
        return Err("image is required".to_string());
    }
    let host_port = if spec.host_port == 0 { DESKTOP_PORT } else { spec.host_port };
    let mut args = vec!["run".to_string(), "-d".to_string()];
    if let Some(name) = &spec.name {
        args.push("--name".into());
        args.push(name.clone());
    }
    args.push("-p".into());
    args.push(format!("{host_port}:{DESKTOP_PORT}"));
    if spec.dashboard_port != 0 {
        args.push("-p".into());
        args.push(format!("{}:{DASHBOARD_PORT}", spec.dashboard_port));
    }
    if let Some(shm) = &spec.shm_size {
        args.push("--shm-size".into());
        args.push(shm.clone());
    }
    if let Some(mem) = &spec.memory {
        args.push("--memory".into());
        args.push(mem.clone());
    }
    if let Some(cpus) = &spec.cpus {
        args.push("--cpus".into());
        args.push(cpus.clone());
    }
    if spec.gpu {
        args.push("--device".into());
        args.push("/dev/dri".into());
    }
    for e in &spec.env {
        args.push("-e".into());
        args.push(e.clone());
    }
    for v in &spec.volumes {
        args.push("-v".into());
        args.push(v.clone());
    }
    args.push(spec.image.clone());
    Ok(args)
}

/// Curated marketplace. Mirrors the published image catalog.
pub fn marketplace() -> Vec<App> {
    fn app(
        id: &str,
        name: &str,
        tagline: &str,
        category: &str,
        kind: &str,
        ram: &str,
        gpu: bool,
        featured: bool,
    ) -> App {
        App {
            id: id.to_string(),
            name: name.to_string(),
            tagline: tagline.to_string(),
            category: category.to_string(),
            kind: kind.to_string(),
            desktop: None,
            preset: None,
            flavor: None,
            ram: ram.to_string(),
            gpu,
            featured,
            image: image_ref(id),
        }
    }
    fn desktop(mut a: App, d: &str) -> App {
        a.desktop = Some(d.to_string());
        a
    }
    fn preset(mut a: App, p: &str) -> App {
        a.preset = Some(p.to_string());
        a
    }
    fn flavor(mut a: App, f: &str) -> App {
        a.flavor = Some(f.to_string());
        a
    }

    vec![
        preset(desktop(app("xfce4-minimal-latest", "XFCE4 Minimal", "Fast, familiar, and light on RAM", "Desktops", "desktop", "512 MB", false, true), "xfce4"), "minimal"),
        preset(desktop(app("kde-none-latest", "KDE Plasma", "A modern, highly configurable Qt desktop", "Desktops", "desktop", "1.5 GB", false, false), "kde"), "none"),
        preset(desktop(app("gnome-none-latest", "GNOME", "The sleek, opinionated desktop", "Desktops", "desktop", "2 GB", false, false), "gnome"), "none"),
        preset(desktop(app("cinnamon-minimal-latest", "Cinnamon", "Familiar Windows-like layout", "Desktops", "desktop", "1 GB", false, false), "cinnamon"), "minimal"),
        preset(desktop(app("i3-minimal-latest", "i3 (tiling)", "Keyboard-driven tiling window manager", "Desktops", "desktop", "128 MB", false, false), "i3"), "minimal"),
        preset(desktop(app("lxqt-minimal-latest", "LXQt", "Barely-there Qt desktop", "Desktops", "desktop", "256 MB", false, false), "lxqt"), "minimal"),

        preset(desktop(app("kde-gaming-latest", "Gaming Rig", "KDE + Steam + Wine, CPU-rendered", "Gaming", "preset", "4 GB", true, true), "kde"), "gaming"),
        preset(desktop(app("xfce4-development-latest", "Developer Workstation", "XFCE4 with common toolchains preinstalled", "Development", "preset", "2 GB", false, true), "xfce4"), "development"),
        preset(desktop(app("kde-content-creation-latest", "Creator Studio", "KDE with creative tooling", "Content Creation", "preset", "3 GB", false, true), "kde"), "content-creation"),
        preset(desktop(app("xfce4-office-latest", "Office Suite", "XFCE4 with document and productivity apps", "Office", "preset", "2 GB", false, false), "xfce4"), "office"),

        flavor(app("kali-latest", "Kali Linux", "Security tooling on an XFCE4 base", "Security", "flavor", "2 GB", false, true), "kali"),
        flavor(app("parrot-latest", "Parrot Security OS", "Security and privacy toolkit, MATE", "Security", "flavor", "2 GB", false, false), "parrot"),

        flavor(app("pearos-latest", "pearOS", "A macOS-inspired KDE Plasma desktop", "Distros", "flavor", "1.5 GB", false, true), "pearos"),
        flavor(app("pop-os-latest", "Pop!_OS", "System76's GNOME experience", "Distros", "flavor", "2 GB", false, false), "pop-os"),
        flavor(app("nixos-latest", "NixOS", "Openbox shell with the Nix package manager", "Distros", "flavor", "256 MB", false, false), "nixos"),
        flavor(app("linuxmint-latest", "Linux Mint", "Cinnamon with the Mint feel", "Distros", "flavor", "1 GB", false, false), "linuxmint"),
        flavor(app("ubuntu-studio-latest", "Ubuntu Studio", "KDE with creative tooling", "Content Creation", "flavor", "3 GB", false, false), "ubuntu-studio"),
        flavor(app("kubuntu-latest", "Kubuntu", "Ubuntu with KDE Plasma", "Distros", "flavor", "1.5 GB", false, false), "kubuntu"),
        flavor(app("xubuntu-latest", "Xubuntu", "Ubuntu with XFCE4", "Distros", "flavor", "512 MB", false, false), "xubuntu"),
        flavor(app("lubuntu-latest", "Lubuntu", "Ubuntu with the light LXQt desktop", "Distros", "flavor", "256 MB", false, false), "lubuntu"),
        flavor(app("ubuntu-mate-latest", "Ubuntu MATE", "Ubuntu with the MATE desktop", "Distros", "flavor", "512 MB", false, false), "ubuntu-mate"),
        flavor(app("ubuntu-budgie-latest", "Ubuntu Budgie", "Ubuntu with the Budgie desktop", "Distros", "flavor", "1 GB", false, false), "ubuntu-budgie"),
        flavor(app("ubuntu-kylin-latest", "Ubuntu Kylin", "Ubuntu with the UKUI desktop", "Distros", "flavor", "1 GB", false, false), "ubuntu-kylin"),
        flavor(app("ubuntu-unity-latest", "Ubuntu Unity", "The classic Unity shell", "Distros", "flavor", "1 GB", false, false), "ubuntu-unity"),
        flavor(app("ubuntu-edubuntu-latest", "Ubuntu Edubuntu", "GNOME tuned for education", "Distros", "flavor", "2 GB", false, false), "ubuntu-edubuntu"),
        flavor(app("fastvm-os-latest", "FastVM OS", "The FastVM appliance shell", "Distros", "flavor", "1 GB", false, false), "fastvm-os"),

        app("browser-latest", "Browser only", "Just a browser, no desktop", "Minimal", "single", "256 MB", false, false),
        app("discord-latest", "Discord only", "Just Discord, no desktop", "Minimal", "single", "256 MB", false, false),
        app("vscode-latest", "VSCodium only", "Just the editor, no desktop", "Minimal", "single", "256 MB", false, false),
        app("terminal-latest", "Terminal only", "A bare terminal, no desktop", "Minimal", "single", "128 MB", false, false),
    ]
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn catalog_sizes() {
        assert_eq!(DESKTOPS.len(), 36);
        assert_eq!(PRESETS.len(), 6);
        assert_eq!(FLAVORS.len(), 16);
        assert_eq!(SINGLE_APPS.len(), 4);
    }

    #[test]
    fn variant_count_matches_readme() {
        assert_eq!(variant_count(), 236);
    }

    #[test]
    fn tags_build_and_validate() {
        assert_eq!(desktop_tag("pearos", "gaming").unwrap(), "pearos-gaming-latest");
        assert_eq!(flavor_tag("kali").unwrap(), "kali-latest");
        assert_eq!(single_app_tag("browser").unwrap(), "browser-latest");
        assert!(desktop_tag("nope", "none").is_err());
        assert!(desktop_tag("xfce4", "nope").is_err());
        assert!(flavor_tag("nope").is_err());
    }

    #[test]
    fn default_run_args() {
        let spec = RunSpec { image: image_ref("xfce4-none-latest"), ..Default::default() };
        assert_eq!(
            build_run_args(&spec).unwrap(),
            vec!["run", "-d", "-p", "3000:3000", "ghcr.io/cloudcompile/fastvm:xfce4-none-latest"]
        );
    }

    #[test]
    fn full_run_args() {
        let spec = RunSpec {
            image: "x:pearos-latest".into(),
            host_port: 3000,
            dashboard_port: 3001,
            name: Some("FastVM-pearOS".into()),
            shm_size: Some("4gb".into()),
            gpu: true,
            env: vec!["TZ=Etc/UTC".into()],
            ..Default::default()
        };
        assert_eq!(
            build_run_args(&spec).unwrap(),
            vec![
                "run", "-d", "--name", "FastVM-pearOS", "-p", "3000:3000", "-p", "3001:8099",
                "--shm-size", "4gb", "--device", "/dev/dri", "-e", "TZ=Etc/UTC", "x:pearos-latest"
            ]
        );
    }

    #[test]
    fn run_args_require_image() {
        assert!(build_run_args(&RunSpec::default()).is_err());
    }

    #[test]
    fn marketplace_is_populated_and_consistent() {
        let apps = marketplace();
        assert!(apps.len() >= 25, "marketplace should list at least 25 apps");
        assert!(apps.iter().any(|a| a.id == "pearos-latest"));
        assert!(apps.iter().any(|a| a.featured));
        // Every listed image must be a real, validated tag.
        for a in &apps {
            assert!(a.image.starts_with(REGISTRY));
            match a.kind.as_str() {
                "desktop" => {
                    desktop_tag(a.desktop.as_deref().unwrap(), a.preset.as_deref().unwrap()).unwrap();
                }
                "preset" => {
                    desktop_tag(a.desktop.as_deref().unwrap(), a.preset.as_deref().unwrap()).unwrap();
                }
                "flavor" => {
                    flavor_tag(a.flavor.as_deref().unwrap()).unwrap();
                }
                "single" => {
                    let name = a.id.strip_suffix("-latest").unwrap();
                    single_app_tag(name).unwrap();
                }
                other => panic!("unexpected kind: {other}"),
            }
        }
    }
}
