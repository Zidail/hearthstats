class Card extends React.Component {

  constructor(props) {
    super(props);

    let { name } = this.props.card;
    let cardName = name
                 .trim()
                 .replace(/[^a-zA-Z0-9-\s-\']/g, '')
                 .replace(/[^a-zA-Z0-9-]/g, '-')
                 .replace(/--/g, '-')
                 .toLowerCase();

    cardName = cardName === 'si7-agent' ? 'si-7-agent' : cardName;

    const imgSrc = `//s3.amazonaws.com/hearthstatsprod/full_card/${cardName}.png`

    this.state = {
      hasLoaded: false,
      imgSrc: imgSrc,
    };

    this._handleClick = this._handleClick.bind(this);
  }

  componentDidMount() {
    this.setState({
      hasLoaded: true,
    });
  }

  _handleClick(event) {
    const { click } = this.props;

    click(event);
  }

  render() {
    const { hasLoaded, imgSrc } = this.state;
    const { cName } = this.props;

    const className = `deckbuilder-img ${cName}`;
    const imageSource = hasLoaded ? imgSrc : '/assets/blind_draft/deckbuilder-card-back.png';

    return (
      <img src={imageSource} className={className} onClick={this._handleClick} />
    );
  }
}
