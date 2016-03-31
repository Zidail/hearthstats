class DeckCard extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      hover: false,
    };

    this._mouseOut = this._mouseOut.bind(this);
    this._mouseOver = this._mouseOver.bind(this);
    this._onClick = this._onClick.bind(this);
  }

  _mouseOver(event) {
    const { clientX, clientY } = event;
    const { scrollY, innerHeight } = window;

    let deckImageStyle = {
      height: '300px',
      left: `${clientX + 40}px`,
      position: 'fixed',
      zIndex: '2000',
    };

    if( event.clientY + 500 > window.scrollY + window.innerHeight ) {
      deckImageStyle.bottom = '5px';
    } else {
      deckImageStyle.top = `${event.clientY + 20}px`;
    }

    this.setState({
      hover: true,
      deckImageStyle: deckImageStyle,
    });
  }

  _mouseOut() {
    this.setState({
      hover: false,
      deckImageStyle: null,
    });
  }

  _onClick(event) {
    const { type, click } = this.props;

    if (type === 'edit') {
      click(event);
    }
  }

  _renderFullCardView(value, id, cardName, deckImageStyle, src) {
    if (value) {
      const fullDeckImage = <img
                              id="deckBuilderFullCardView"
                              key={id}
                              ref="fullDeckImage"
                              src={src}
                              style={deckImageStyle}
                            />;

      return fullDeckImage;
    }
  }

  render() {
    let { qty, card } = this.props;
    let { name, mana, id, rarity_id } = card;
    let { hover, deckImageStyle } = this.state;
    let cardName = name
                 .trim()
                 .replace(/[^a-zA-Z0-9-\s-\']/g, '')
                 .replace(/[^a-zA-Z0-9-]/g, '-')
                 .replace(/--/g, '-')
                 .toLowerCase();

    cardName = cardName === 'si7-agent' ? 'si-7-agent' : cardName;

    let wrapperClass;

    if (qty === 2) {
      wrapperClass = 'two';
    } else if (qty === 5) {
      wrapperClass = 'legendary';
    } else {
      wrapperClass = 'normal';
    }

    const cardClass = `card cardWrapper ${wrapperClass}`;
    const baseUrl = '//s3.amazonaws.com/hearthstatsprod/';
    const fullImgUrl = `${baseUrl}full_card/${cardName}.png`;
    const thumbImgUrl = `${baseUrl}deck_images/${cardName}.png`;

    return(
      <div onMouseOver={this._mouseOver} onMouseOut={this._mouseOut}>
        <div onClick={this._onClick} key={cardName} alt={cardName} className={cardClass}>
          <div className="mana">
            {mana}
          </div>
          <div className="name">
            {name}
          </div>
          <div className="qty">
            {qty}
          </div>
          <img src={thumbImgUrl} className="image" />
          <div className="bg" />
        </div>
        { this._renderFullCardView(hover, id, cardName, deckImageStyle, fullImgUrl) }
      </div>
    );
  }
}

