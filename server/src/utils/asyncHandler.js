// Envolve uma rota async pra encaminhar qualquer rejeição pro Express via
// next(err), em vez de virar uma unhandled rejection que derruba o
// processo inteiro (Express 4 não faz isso sozinho — só a partir do 5).
function asyncHandler(fn) {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

module.exports = asyncHandler;
