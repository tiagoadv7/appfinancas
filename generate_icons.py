#!/usr/bin/env python3
"""
Script para gerar ícones do app FinançasApp
Converte o SVG de logo em PNGs nos tamanhos necessários usando Inkscape
"""

import subprocess
import os
import platform
import sys

def find_inkscape():
    """Encontra o caminho para o executável Inkscape"""
    if platform.system() == 'Windows':
        possible_paths = [
            r'C:\Program Files\Inkscape\bin\inkscape.exe',
            r'C:\Program Files\Inkscape\inkscape.exe',
            r'C:\Program Files (x86)\Inkscape\bin\inkscape.exe',
            r'C:\Program Files (x86)\Inkscape\inkscape.exe',
        ]
        for path in possible_paths:
            if os.path.exists(path):
                return path
    else:
        # Linux/macOS
        result = subprocess.run(['which', 'inkscape'], capture_output=True)
        if result.returncode == 0:
            return result.stdout.decode().strip()
    return None

def export_png_from_svg(svg_path, output_path, width, height):
    """Exporta um PNG a partir de um SVG usando Inkscape"""
    inkscape = find_inkscape()
    if not inkscape:
        print("⚠️  Inkscape não encontrado. Instale em https://inkscape.org")
        return False
    
    # Criar diretório se não existir
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    # Executar Inkscape para converter SVG em PNG
    cmd = [
        inkscape,
        svg_path,
        f'--export-filename={output_path}',
        f'--export-width={width}',
        f'--export-height={height}',
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=False)
        return result.returncode == 0 or os.path.exists(output_path)
    except Exception as e:
        print(f"❌ Erro ao exportar {output_path}: {e}")
        return False

def generate_all_icons():
    """Gera todos os ícones nos tamanhos necessários a partir do SVG logo"""
    
    # Tamanhos necessários para Android, iOS, Web e macOS
    sizes_config = {
        'web/icons/Icon-192.png': 192,
        'web/icons/Icon-512.png': 512,
        'web/icons/Icon-maskable-192.png': 192,
        'web/icons/Icon-maskable-512.png': 512,
        'web/favicon.png': 64,
        'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
        'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
        'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
        'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
        'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png': 20,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png': 40,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png': 60,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png': 29,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png': 58,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png': 87,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png': 40,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png': 80,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png': 120,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png': 120,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png': 180,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png': 76,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png': 152,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png': 167,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png': 1024,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png': 16,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png': 32,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png': 64,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png': 128,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png': 256,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png': 512,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png': 1024,
    }
    
    base_path = os.path.dirname(os.path.abspath(__file__))
    svg_path = os.path.join(base_path, 'assets', 'images', 'logo.svg')
    
    if not os.path.exists(svg_path):
        print(f"❌ SVG não encontrado: {svg_path}")
        return False
    
    print(f"📁 SVG de origem: {svg_path}\n")
    
    success_count = 0
    for relative_path, size in sizes_config.items():
        full_path = os.path.join(base_path, relative_path)
        
        if export_png_from_svg(svg_path, full_path, size, size):
            print(f'✓ Criado: {relative_path} ({size}x{size})')
            success_count += 1
        else:
            print(f'❌ Falha: {relative_path} ({size}x{size})')
    
    print(f'\n✅ {success_count}/{len(sizes_config)} ícones gerados com sucesso!')
    return success_count == len(sizes_config)

if __name__ == '__main__':
    generate_all_icons()
