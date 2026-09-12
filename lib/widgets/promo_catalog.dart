import 'package:flutter/material.dart';

class PromoBenefit {
  final IconData icon;
  final String title;
  final String description;
  const PromoBenefit(this.icon, this.title, this.description);
}

class PromoDetailData {
  final String storeName;
  final String storeCategory;
  final double rating;
  final String title;
  final String description;
  final String tag;
  final String? expiresIn;
  final int currentStamps;
  final int totalStamps;
  final String stampsHint;
  final Color highlightBg;
  final List<Color> heroGradient;
  final String heroEmoji;
  final String imageAsset;
  final List<PromoBenefit> benefits;
  final String ctaText;

  const PromoDetailData({
    required this.storeName,
    required this.storeCategory,
    required this.rating,
    required this.title,
    required this.description,
    required this.tag,
    required this.expiresIn,
    required this.currentStamps,
    required this.totalStamps,
    required this.stampsHint,
    required this.highlightBg,
    required this.heroGradient,
    required this.heroEmoji,
    required this.imageAsset,
    required this.benefits,
    required this.ctaText,
  });
}

class PromoCatalog {
  static const featured = PromoDetailData(
    storeName: 'Café do Ponto',
    storeCategory: 'Cafeteria Premium',
    rating: 4.8,
    title: 'Ganhe um café grátis ao completar 10 compras',
    description:
        'Cada café comprado acima de R\$ 12,00 garante um selo no seu cartão fidelidade digital. Aproveite o melhor sabor da cidade.',
    tag: 'Campanha Ativa',
    expiresIn: 'Expira em 24 dias',
    currentStamps: 7,
    totalStamps: 10,
    stampsHint: 'Faltam apenas 3 cafés!',
    highlightBg: Color(0xFFFFF1B6),
    heroGradient: [Color(0xFF6B4423), Color(0xFF3B2515)],
    heroEmoji: '☕',
    imageAsset: 'assets/images/artisancoffee_thumb.jpg',
    benefits: [
      PromoBenefit(
        Icons.coffee,
        'Café Especial Grátis',
        'Válido para qualquer item do menu até R\$ 18,00.',
      ),
      PromoBenefit(
        Icons.bolt,
        'Pontos em Dobro',
        'Ganhe 2x pontos em compras nas segundas-feiras.',
      ),
      PromoBenefit(
        Icons.cake,
        'Mimo de Aniversário',
        'Um pedaço de bolo por nossa conta no seu dia.',
      ),
    ],
    ctaText: 'Como acumular selos',
  );

  static final List<PromoDetailData> list = [
    featured,
    const PromoDetailData(
      storeName: 'Artisan Coffee',
      storeCategory: 'Cafeteria',
      rating: 4.8,
      title: 'Café Grátis a cada 10 compras',
      description:
          'A cada 10 cafés comprados em qualquer unidade Artisan, o 11º é por nossa conta. Apresente este voucher no caixa para validar o resgate.',
      tag: 'Quase lá!',
      expiresIn: null,
      currentStamps: 8,
      totalStamps: 10,
      stampsHint: 'Faltam apenas 2 cafés!',
      highlightBg: Color(0xFFFFE0A8),
      heroGradient: [Color(0xFF8B5E3C), Color(0xFF4B2E1F)],
      heroEmoji: '☕',
      imageAsset: 'assets/images/artisancoffee_thumb.jpg',
      benefits: [
        PromoBenefit(
          Icons.coffee,
          'Café Grátis',
          'Resgate em qualquer unidade Artisan Coffee.',
        ),
        PromoBenefit(
          Icons.star,
          'Pontos extras',
          'Acumule pontos mesmo durante a promoção.',
        ),
        PromoBenefit(
          Icons.share,
          'Indique amigos',
          '500 pontos por amigo que entrar no programa.',
        ),
      ],
      ctaText: 'Como acumular selos',
    ),
    const PromoDetailData(
      storeName: 'Studio Estrela',
      storeCategory: 'Beleza',
      rating: 4.9,
      title: '20% OFF em cortes',
      description:
          'Aproveite 20% de desconto em qualquer corte de cabelo do Studio Estrela. Válido para clientes cadastrados no programa Acumula Aí.',
      tag: 'Novo',
      expiresIn: 'Expira em 7 dias',
      currentStamps: 2,
      totalStamps: 5,
      stampsHint: 'Faltam apenas 3 cortes!',
      highlightBg: Color(0xFFE9D5F5),
      heroGradient: [Color(0xFF5B0A8F), Color(0xFF3F0664)],
      heroEmoji: '✂️',
      imageAsset: 'assets/images/studioestrela_thumb.jpg',
      benefits: [
        PromoBenefit(
          Icons.content_cut,
          '20% OFF',
          'Desconto válido em qualquer corte do mês.',
        ),
        PromoBenefit(
          Icons.brush,
          'Hidratação grátis',
          'A cada 5 cortes, hidratação capilar grátis.',
        ),
        PromoBenefit(
          Icons.calendar_today,
          'Agenda flexível',
          'Agendamento online pelo app.',
        ),
      ],
      ctaText: 'Como participar',
    ),
    const PromoDetailData(
      storeName: 'Grão & Arte Cafeteria',
      storeCategory: 'Cafeteria',
      rating: 4.6,
      title: 'Compre 1, leve 2 em bolos',
      description:
          'Compre um bolo e leve outro por nossa conta. Válido de terça a quinta, das 14h às 18h em todas as unidades Grão & Arte.',
      tag: 'Voucher',
      expiresIn: 'Expira em 14 dias',
      currentStamps: 1,
      totalStamps: 3,
      stampsHint: 'Faltam apenas 2 bolos!',
      highlightBg: Color(0xFFFCE4EC),
      heroGradient: [Color(0xFFE91E63), Color(0xFFAD1457)],
      heroEmoji: '🍰',
      imageAsset: 'assets/images/graoarte_thumb.jpg',
      benefits: [
        PromoBenefit(
          Icons.cake,
          'Bolo grátis',
          'Leve 2 bolos pagando 1, terça a quinta.',
        ),
        PromoBenefit(
          Icons.coffee,
          'Café incluso',
          'Cada bolo vem com um café espresso grátis.',
        ),
        PromoBenefit(
          Icons.card_giftcard,
          'Vale presente',
          'Surpreenda alguém com um cupom Grão & Arte.',
        ),
      ],
      ctaText: 'Como participar',
    ),
    const PromoDetailData(
      storeName: 'Padoca do Bairro',
      storeCategory: 'Restaurante',
      rating: 4.7,
      title: 'Pontos em dobro na quarta',
      description:
          'Toda quarta-feira, suas compras valem pontos em dobro. Aproveite pães, bolos e salgados fresquinhos na Padoca do Bairro.',
      tag: 'Quarta',
      expiresIn: 'Permanente',
      currentStamps: 5,
      totalStamps: 10,
      stampsHint: 'Faltam apenas 5 compras!',
      highlightBg: Color(0xFFFFE0A8),
      heroGradient: [Color(0xFFFF8A65), Color(0xFFD84315)],
      heroEmoji: '🥐',
      imageAsset: 'assets/images/padocadobairro_thumb.jpg',
      benefits: [
        PromoBenefit(
          Icons.flash_on,
          'Pontos em dobro',
          'Toda quarta, sua compra vale o dobro de pontos.',
        ),
        PromoBenefit(
          Icons.local_dining,
          'Café da manhã',
          'Combo pão fresco + café a partir de R\$ 8,90.',
        ),
        PromoBenefit(
          Icons.delivery_dining,
          'Delivery grátis',
          'Pedidos acima de R\$ 25 não pagam entrega.',
        ),
      ],
      ctaText: 'Como acumular selos',
    ),
  ];
}
