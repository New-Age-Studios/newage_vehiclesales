import React from 'react';

export const TermsBox: React.FC = () => {
  return (
    <div className="space-y-3 mb-4">
      <h3 className="text-[10px] font-black text-zinc-900 uppercase tracking-widest border-b border-zinc-100 pb-1">Termo de Responsabilidade</h3>
      <div className="text-[10px] text-zinc-600 leading-normal text-justify space-y-1.5 font-medium">
        <p>
          1. O COMPRADOR declara ter vistoriado o veículo e aceitá-lo no estado em que se encontra.
        </p>
        <p>
          2. A transferência de propriedade é imediata após a confirmação do pagamento.
        </p>
      </div>
    </div>
  );
};
