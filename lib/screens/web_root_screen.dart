import 'package:flutter/material.dart';
import '../widgets/web_sidebar.dart';
import 'web_dashboard_screen.dart';
import 'web_cadastro_campanha_screen.dart';
import 'web_postar_promo_screen.dart';
import 'web_aprovacao_screen.dart';
import 'web_relatorio_clientes_screen.dart';

class WebRootScreen extends StatefulWidget {
  const WebRootScreen({super.key});

  @override
  State<WebRootScreen> createState() => _WebRootScreenState();
}

class _WebRootScreenState extends State<WebRootScreen> {
  AdminSection _current = AdminSection.dashboard;

  void _select(AdminSection s) => setState(() => _current = s);

  @override
  Widget build(BuildContext context) {
    switch (_current) {
      case AdminSection.dashboard:
        return WebDashboardScreen(onSelect: _select);
      case AdminSection.cadastro:
        return WebCadastroCampanhaScreen(onSelect: _select);
      case AdminSection.postar:
        return WebPostarPromoScreen(onSelect: _select);
      case AdminSection.aprovacao:
        return WebAprovacaoScreen(onSelect: _select);
      case AdminSection.relatorio:
        return WebRelatorioClientesScreen(onSelect: _select);
    }
  }
}
