class DeckBuild extends React.Component {

  constructor(props) {
    super(props);
    const { klass, deck } = this.props;

    this.state = {
      cardstring: '',
      chosenKlass: klass,
      deck: deck,
      klassSelected: deck != null && deck.klass_id != null,
      moveOn: false,
      editBack: false,
    };

    this._handleKlassSelect = this._handleKlassSelect.bind(this);
    this._handleCardSelect = this._handleCardSelect.bind(this);
    this._handleCardResubmit = this._handleCardResubmit.bind(this);
    this._renderDetailSelect = this._renderDetailSelect.bind(this);
    this._renderCardSelect = this._renderCardSelect(this);
  }

  componentWillMount() {
    const { type, deck } = this.props;
    const { klass_id, cardstring } = deck;

    if (type === 'edit') {
      this.setState({
        cardstring,
        chosenKlass: klass_id,
      });
    }
  }

  _handleKlassSelect(klass_id) {
    this.setState({
      chosenKlass: klass_id,
      klassSelected: true
    });
  }

  _handleCardSelect(cardstringText) {
    this.setState({
      crdstring: cardstringText,
      moveOn: true,
    });
  }

  _handleCardResubmit() {
    this.setState({
      moveOn: false,
      editBack: true,
    });
  }

  _renderDetailSelect() {
    const { type, currentVersion, deck, cards, archtypes } = this.props;
    const { chosenKlass, cardstring } = this.state;

    const detailSelect = <DetailSelect {...{ type, currentVersion, deck, cards, cardstring }} klass={chosenKlass} archtype={archtypes} backButton={this._handleCardResubmit} />;

    return detailSelect;
  }

  _renderCardSelect() {
    const { editBack, cardstring, chosenKlass, } = this.state;
    const { cards, deck, type } = this.props;

    const cardSelect = <div>
                         <CardSelect {... { editBack, cardstring, cards, deck, type }} klass={chosenKlass} submitClick={this._handleCardSelect}
                         />
                       </div>;

    return cardSelect;
  }

  render() {
    const { klassSelected, moveOn } = this.state;

    if (klassSelected && !moveOn) {
      return(this._renderCardSelect);
    } else {
      return(this._renderDetailSelect);
    }
  }
}